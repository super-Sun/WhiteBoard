//
//  MyBezierPath.h
//  10-画板
//
//  Created by sunluwei on 16/10/31.
//  Copyright © 2016年 Hader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCRect.h"
#import "SCConst.h"

@interface MyBezierPath : UIBezierPath

@property (nonatomic, assign) int pathID;
/** 当前路径的颜色 */
@property (nonatomic, strong) UIColor *color;
/**是否填充*/
@property (nonatomic, assign) BOOL isFill;
/**填充颜色*/
@property (nonatomic, strong) UIColor *fillColor;
/**Rect*/
@property (nonatomic, assign) CGRect rect;
/**图形的类型：type*/
@property (nonatomic, assign) DrawType type;
/**线构成的所有点points*/
@property (nonatomic, strong) NSArray *points;

/**
 *  创建beze对象
 *
 *  @param rect 传入的rect
 *  @param type 类型
 *
 *  @return 对象
 */
+ (instancetype)bezierPathWithRect:(CGRect)rect andType:(DrawType)type;


- (void)setProperyeWithPath:(MyBezierPath *)path andNewRect:(CGRect)rect;

@end
