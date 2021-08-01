//
//  BNObject.m
//  BNKVC_KVODemo
//
//  Created by binbinwang on 2021/8/1.
//

#import "BNObject.h"
#import "BNObjectDynamic.h"

@interface BNObject () {
    NSInteger num;
}

@end

@implementation BNObject

- (void)setNum:(NSInteger)numTmp {
    num = numTmp;
}

@end
