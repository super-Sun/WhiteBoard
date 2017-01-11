//
//  HandleImageView.h
//  10-画板
//
//  Created by sunluwei on 16/10/31.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HandleImageView;
@protocol handleImageViewDelegate <NSObject>

- (void)handleImageView:(HandleImageView *)handleImageView newImage:(UIImage *)newImage;

@end


@interface HandleImageView : UIView

/** <#注释#> */
@property (nonatomic, strong) UIImage *image;

/** <#注释#> */
@property (nonatomic, weak) id<handleImageViewDelegate> delegate;
/** 大小*/
@property (nonatomic, assign) CGRect ImgRect;



@end
