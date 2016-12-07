//
//  MyBezierPath.m
//  10-画板
//
//  Created by sunluwei on 16/10/31.
//  Copyright © 2016年 Hader. All rights reserved.
//

#import "MyBezierPath.h"

@implementation MyBezierPath

+ (instancetype)bezierPathWithRect:(CGRect)rect andType:(DrawType)type {
    if (type == DrawTypeEllipse || type == DrawTypeEllipseFill) {
        //椭圆
        return [self bezierPathWithOvalInRect:rect];
    } else if (type == DrawTypeRectangle || type == DrawTypeRectangleFill) {
        //矩形
        return [self bezierPathWithRect:rect];
    }
    
    return [self bezierPath];
    
}

- (void)setProperyeWithPath:(MyBezierPath *)path andNewRect:(CGRect)rect{
    
    self.type = path.type;
    
    self.pathID = path.pathID;

    self.color = path.color;

    self.fillColor = path.fillColor;
    
    self.isFill = path.isFill;
    
    self.rect = rect;
    
    self.points = path.points;
    
}

@end
