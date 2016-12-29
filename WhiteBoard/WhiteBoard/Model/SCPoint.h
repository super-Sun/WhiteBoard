//
//  SCPoint.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPoint : NSObject

/**x*/
@property (nonatomic, assign) int x;
/**y*/
@property (nonatomic, assign) int y;

+ (instancetype)point:(CGPoint)point;

@end
