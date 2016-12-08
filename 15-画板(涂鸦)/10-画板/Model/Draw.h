//
//  draw.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SCConst.h"

@interface Draw : NSObject
/**对象ID*/
@property (nonatomic, assign) int ObjId;
/**对象IDs*/
@property (nonatomic, strong) NSArray *ObjIds;
/**画笔颜色*/
@property (nonatomic, strong) UIColor *color;
/**画笔线宽*/
@property (nonatomic, assign) int lineWidth;
/**RECT*/
@property (nonatomic, assign) CGRect rect;
/**点个数*/
@property (nonatomic, assign) int nCount;
/**点数据*/
@property (nonatomic, strong) NSArray *points;
/**填充性*/
@property (nonatomic, assign) BOOL isFill;
/**图形类型*/
@property (nonatomic, assign) DrawType type;
/**添加的文字描述*/
@property (nonatomic, copy) NSString *text;
/**移动对象point*/
@property (nonatomic, assign) CGPoint point;

@end
