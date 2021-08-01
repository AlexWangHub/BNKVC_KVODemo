## 一、KVO（Key-Value observing）

### （一）KVO的特点

- KVO 是OC对`观察者模式`的又一实现
- 苹果使用了 isa混写（isa-swizzling）技术 实现 KVO

### （二）如何通过 isa混写技术 实现 KVO ？

#### 1. 什么是isa指针

首先isa指针的全称，is a kind of 指针，顾名思义我们可以先理解为指向它所在类型的指针，如果一个类创建了一个实例，那么可以通过这个指针指向找到所在的类，下面打开objc.h文件

```
/// An opaque type that represents an Objective-C class.
typedef struct objc_class *Class;

/// Represents an instance of a class.
struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};
```

看的出每个objc_object对象都有一个指向Class类型的isa指针，再打开runtime.h文件

```
struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif
} OBJC2_UNAVAILABLE;
/* Use `Class` instead of `struct objc_class *` */
```

这里有Class类型的isa指针还有super_class，也可以看出isa指针并不是指向父类指针，这个结构体里面的内容很直观，isa指针、指向父类指针、名称、版本、信息、变量大小、变量列表、方法列表等等，每个objc_object可以通过isa指针找到它的类，并找到想要实现的方法或遵循的协议，由于objc_class也有isa指针，所以objc_class也是一个对象，称为“类对象”，它的isa指针指向他的元类(Meta-Class)，这样一来就很清晰了，每个对象通过isa指针向类中查找信息，类对象通过isa指针向元类查找信息，每个实例对象或类对象根据super_class指针都可以找到它们的父类，至此整个继承传递结构出来了

(isa + superClass) 完成了类对象的实例化与串联，

isa：是一个Class 类型的指针. 每个实例对象有个isa的指针,他指向对象的类，而Class里也有个isa的指针, 指向meteClass(元类)。元类保存了类方法的列表。当类方法被调用时，先会从本身查找类方法的实现，如果没有，元类会向他父类查找该方法。同时注意的是：元类（meteClass）也是类，它也是对象。元类也有isa指针,它的isa指针最终指向的是一个根元类(root meteClass).根元类的isa指针指向本身，这样形成了一个封闭的内循环。

super_class：父类，如果该类已经是最顶层的根类,那么它为NULL。

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1aya8g09j30gm0hdwfh.jpg)

#### 2. 如何通过 isa混写 实现 KVO ？

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1b0zu8odj30rf0dqt9p.jpg)

KVO 流程：

>> 0. 调用 addObserveForKeyPath A.property
>> 1. 系统runtime创建 NSKVONotifying_A 一个新的类，同时将原先指向 A 类的isa指针指向新创建的类
>> 2. 在新创建的 NSKVONotifying_A 中重写要监听的 property 的 setter 方法

```
KVO 两个关键方法:

// 添加监听
- (void)addObserver:(NSObject *)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(nullable void *)context {
}

// 变更回调
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
}

// 添加 KVO 必须在合适的时机移除！不然会crash
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;


```

NSKVONotifying_A 是 A 的一个子类，在 NSKVONotifying_A 中重写了 A 中相应 property 的 setter 方法。



### （三）调用流程与isa混写校验

#### 1. KVO 调用流程

##### （1）调用KVO

```
[obj addObserver:observer forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
```

##### （2）接收回调

```
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
}
```

#### 2. isa混写校验

调用`po object_getClassName(obj)`，可以发现在添加 KVO 前后，obj的类型发生了改变。

KVO 之前：

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1b804dwpj30r409hmyb.jpg)

KVO 之后：

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1b8cjynfj30re0byjsr.jpg)

Tips: 如果对一个类添加多个 KVO，会进行多次 isa混写 吗？

不会的，只会多创建出一个 NSKVONotifying_object。 

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1b9chghsj30qv0ebjt2.jpg)


## 二、KVC（Key-Value Coding 键值编码）

### （一）KVC 的特点

KVC 是苹果提供的 可以直接「访问对象私有成员变量」和「修改私有成员变量值」的方法。

### （二）KVC 调用流程

#### 1. valueForKey 调用

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1bicgucrj30s50dpab1.jpg)

#### 2. setValue:ForKey: 调用

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1bltgskuj30tf0ctmy6.jpg)

### （三）关于 KVC 的问题

#### 1. KVC 是不是违背了 面向对象编程 的思想？

有没有违背 面向对象编程 的思想，我们首先要明白面向对象的 3 feature 和 5 principle 分别是什么、

3 feature：封装、继承、多态

5 principle：单一职责、开放封闭、Liskov替换、依赖倒置、接口隔离。

实际上 5 principle 对应的是 设计模式 ，KVC 实际上违背的是 面向对象 「3 feature」中的封装原则。

封装，就是将客观事物抽象为逻辑实体，实体的属性和功能相结合，形成一个有机的整体。并对实体的属性和功能实现进行访问控制，向信任的实体开放，对不信任的实体隐藏。通过开放的外部接口即可访问，无需知道功能如何实现。

比如一个类有私有属性，本身对外是没有暴露的，但外界却通过 KVC 直接修改了 私有属性，打破了「封装」的概念。

苹果提供了 KVC，也提供了 制衡 KVC 的方法，即：

```
+ (BOOL)accessInstanceVariablesDirectly {
    return NO;
}
```

如果`accessInstanceVariablesDirectly`方法的返回值为NO，也就意味着这个类不允许通过KVC来修改它的 私密属性 。注意了，是不允许修改私密属性，如果这个类本身已经把接口暴露出去了，那么通过 KVC 还是可以修改这个属性的。（原因可见上文 `setValueForKey` 调用流程图）


#### 2. 工程中什么时候会用到 KVC ？

项目中基本不会使用 KVC（微信工程里用到 KVC 的地方不多于10处）。

#### 3. KVC 改值会触发 KVO 吗？为什么

接着我们开始测试KVC、KVO，我们按如下流程来测试，测试的github代码如下：

[KVO、KVC测试Demo](https://github.com/BNineCoding/BNKVC_KVODemo)

##### （1）对私有property使用 KVC

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1c7y7aiqj30d306daa6.jpg)

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1c7eorlej30q50dvta2.jpg)

#### （2）实例变量可以被 KVC 吗？

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1c8sash4j30ee05y0ss.jpg)

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1c8zwwclj30qo0e2wfw.jpg)

可以

#### （3）对私有property 使用 KVC 会命中 property 的 setter 方法吗？

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1ca3t6iyj30r20f2q3t.jpg)

会命中

#### （4）对 私有实例变量 使用 KVC 会命中 setter 方法吗？

会命中。

私有实例变量没有可自动补全的 setter 方法，有的话也是自己暴露编写 getter/setter。

我发现使用 KVC，是会命中自己编写的 setter 方法的，所以即使没有自动补全 setter ，但系统在 runtime 阶段仍然承认自己编译的 setter 方法：

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1eyghs4sj30ok0dmmy6.jpg)


#### （5）对 私有property 使用 KVO监听，然后使用 KVC 改值，KVO 会有回调吗？

有回调的。

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1fdkcgg5j30x70j4416.jpg)

#### （6）对 私有成员变量 使用 KVO监听，然后使用 KVC 改值，KVO 会有回调吗？

![](https://tva1.sinaimg.cn/large/008i3skNgy1gt1ff5cylfj30yc0g7418.jpg)
