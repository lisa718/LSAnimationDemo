//
//  MyLabel.m
//  CAAnimation
//
//  Created by 董招兵 on 2017/3/3.
//  Copyright © 2017年 大兵布莱恩特. All rights reserved.
//

#import "MyLabel.h"

@implementation MyLabel


- (CGSize)sizeThatFits:(CGSize)size {
    
    CGSize newSize = [super sizeThatFits:size];
    NSLog(@"size =%@",NSStringFromCGSize(newSize));
    
    return newSize;
    
}


@end
