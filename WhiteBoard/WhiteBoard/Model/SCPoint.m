//
//  SCPoint.m
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "SCPoint.h"

@implementation SCPoint

+ (instancetype)point:(CGPoint)point {
    
    SCPoint *pointOjb = [[SCPoint alloc] init];
    
    pointOjb.x = point.x;
    
    pointOjb.y = point.y;
    
    return pointOjb;
}

@end
