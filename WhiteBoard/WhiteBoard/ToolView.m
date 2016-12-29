//
//  ToolView.m
//  WhiteBoard
//
//  Created by sunluwei on 16/12/23.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "ToolView.h"

@interface ToolView()




@end


@implementation ToolView


/***/
- (void)hideView:(BOOL)isHide {
    
    self.alpha = isHide ? 0 : 1.0;

}


- (IBAction)colorBtnClick:(UIButton *)sender {
    
    
    NSLog(@"%ld", sender.tag);
    
    UIColor *selectedColor = nil;
    
    if (sender.tag == 1001) {
        //red
        selectedColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0];
    } else if (sender.tag == 1002) {
        //yellow
        selectedColor = [UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:1.0];
    } else if (sender.tag == 1003) {
        //green
        selectedColor = [UIColor colorWithRed:0 green:1.0 blue:0 alpha:1.0];
    } else if (sender.tag == 1004) {
        //blue
        selectedColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:1.0];
    } else if (sender.tag == 1005){
        //black
        selectedColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    }
    
    //触发代理方法
    if([self.delegate respondsToSelector:@selector(toolViewColorSelected:color:)]) {
        
        [self.delegate toolViewColorSelected:self color:selectedColor];
        
    }
    
    //隐藏view
    [self hideSelf];
}

- (IBAction)lineHeightBtnClick:(UIButton *)sender {
    
    NSLog(@"%ld", sender.tag);
    CGFloat lineHeight = 0;
    if (sender.tag == 2001) {
        //
        lineHeight = 3;
    } else if (sender.tag == 2002) {
        //
        lineHeight = 1;
    }
    
    //触发代理
    if([self.delegate respondsToSelector:@selector(toolViewlineHeightSelected:lineHeight:)]) {
        
        [self.delegate toolViewlineHeightSelected:self lineHeight:lineHeight];
        
    }
    
    
    
    //隐藏view
    [self hideSelf];
    
    
}


- (void)hideSelf {
    //隐藏view
    self.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        
        self.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        self.userInteractionEnabled = YES;
        
    }];
}



+ (ToolView *)instanceToolView
{
    
    NSArray* nibView =  [[NSBundle mainBundle] loadNibNamed:@"ToolView" owner:nil options:nil];
    
    return [nibView firstObject];
   
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if ([super initWithFrame:frame]) {
        //
        
    }
    return self;
}

@end
