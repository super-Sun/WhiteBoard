//
//  RequestResultOther.h
//  10-画板
//
//  Created by sunluwei on 16/11/21.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestResultOther : NSObject
/***/
@property (nonatomic, copy) NSString *message;
/***/
@property (nonatomic, copy) NSString *op;
/***/
@property (nonatomic, copy) NSString *result;
/***/
@property (nonatomic, strong) NSArray *data;

@end
