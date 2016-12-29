//
//  DrawView.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCConst.h"


@class DrawView;
@protocol DrawViewDelegate <NSObject>

- (void)panDrawView:(DrawView *)drawView andData:(NSData *)data;

@end

@interface DrawView : UIView

//清屏
- (void)clear;
//撤销
- (void)undo;
//橡皮擦
- (void)erase;
//设置线的宽度
- (void)setLineWidth:(CGFloat)lineWidth;
//设置线的颜色
- (void)setLineColor:(UIColor *)color;
/**删除手势*/
- (void)removeRecognizer;
/**添加手势*/
- (void)addRecognizer;
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
/**
 *  批量修改线宽
 *
 *  @param lineWidth 线宽
 *  @param pathIDs   ID数组
 */
- (void)iconWidthChangeWithWidth:(int)lineWidth andPathIDs:(NSArray *)pathIDs;

/**文字*/
- (void)drawWithFontText:(NSString *)text andRect:(CGRect)rect andPathID:(int)pathID;
/**文字内容改变*/
- (void)fontContentChangeWithText:(NSString *)text andPathID:(int)pathID;
/**删除paths*/
- (void)removePathsWithPathIDs:(NSArray *)pathIDs;
/**添加图片*/
- (void)drawImageWithImage:(UIImage *)image andPathID:(int)pathID rect:(CGRect)rect;


/** 要绘制的图片 */
@property (nonatomic, strong) UIImage * image;

/** delegate */
@property (nonatomic, weak) id<DrawViewDelegate> delegate;

@end
