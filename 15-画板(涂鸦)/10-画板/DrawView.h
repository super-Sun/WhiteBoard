//
//  DrawView.h
//  10-画板
//
//  Created by sunluwei on 16/10/31.
//  Copyright © 2016年 Hader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCConst.h"



@interface DrawView : UIView

//清屏
- (void)clear;
//撤销
- (void)undo;
//橡皮擦
- (void)erase;
//设置线的宽度
- (void)setLineWith:(CGFloat)lineWidth;
//设置线的颜色
- (void)setLineColor:(UIColor *)color;
/***/
- (void)drawWithPoints:(NSArray *)points andPathID:(int)pathID;
/***/
- (void)iconWithRect:(CGRect)rect andType: (DrawType)type andPathID:(int)pathID;
/**图形的位置改变*/
- (void)iconLocalChangeWithPoint:(CGPoint)point andPathIDs:(NSArray *)pathIDs;
/**图形的大小改变(目前单个大小改变)*/
- (void)iconSizeChangeWithRect:(CGRect)rect andPathID:(int)pathID;
/**
 *  根据ID修改path颜色
 *
 *  @param color   颜色
 *  @param pathIDs <#pathIDs description#>
 */
- (void)iconColorChangeWithColor:(UIColor *)color andPathIDs:(NSArray *)pathIDs;

/**文字*/
- (void)drawWithFontText:(NSString *)text andRect:(CGRect)rect andPathID:(int)pathID;


/** 要绘制的图片 */
@property (nonatomic, strong) UIImage * image;



@end
