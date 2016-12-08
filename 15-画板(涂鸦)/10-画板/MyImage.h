//
//  MyImage.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyImage : UIImage

@property (nonatomic, assign) int pathID;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) CGRect rect;


+ (instancetype)imageWithImage:(UIImage *)image;

@end
