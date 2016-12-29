//
//  ToolView.h
//  WhiteBoard
//
//  Created by sunluwei on 16/12/23.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ToolView;
@protocol ToolViewDelegate <NSObject>
/**
 *  颜色选择
 *
 *  @param toolView toolView
 *  @param color    选择的颜色
 */
- (void)toolViewColorSelected:(ToolView *)toolView color:(UIColor *)color;
/**
 *  线宽选择
 *
 *  @param toolView   toolView
 *  @param lineHeight 选择的线宽
 */
- (void)toolViewlineHeightSelected:(ToolView *)toolView lineHeight:(CGFloat )lineWidht;

@end


@interface ToolView : UIView

@property (nonatomic ,weak) id<ToolViewDelegate> delegate;

+ (ToolView *)instanceToolView;

/***/
- (void)hideView:(BOOL)isHide;

@end
