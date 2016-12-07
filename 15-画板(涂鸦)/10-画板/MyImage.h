//
//  MyImage.h
//  10-画板
//
//  Created by sunluwei on 16/12/6.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyImage : UIImage

@property (nonatomic, assign) int pathID;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) CGRect rect;


+ (instancetype)imageWithImage:(UIImage *)image;

@end
