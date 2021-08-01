//
//  ViewController.m
//  BNKVC_KVODemo
//
//  Created by binbinwang on 2021/8/1.
//

#import "ViewController.h"
#import "BNObject.h"
#import <objc/runtime.h>

#define BNObserverKeyPath @"num"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BNObject *obj = [[BNObject alloc] init];
    
    [obj addObserver:self forKeyPath:BNObserverKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    NSInteger num = [[obj valueForKey:@"num"] intValue];
    NSLog(@"ViewController before-KVC num:%ld",(long)num);
    [obj setValue:@(10) forKey:@"num"];
    num = [[obj valueForKey:@"num"] intValue];
    NSLog(@"ViewController after-KVC num:%ld",(long)num);
    
    [obj removeObserver:self forKeyPath:BNObserverKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    id newNum = [change objectForKey:NSKeyValueChangeNewKey];
    NSLog(@"observeValueForKeyPath newNum----------%@",newNum);
}


@end
