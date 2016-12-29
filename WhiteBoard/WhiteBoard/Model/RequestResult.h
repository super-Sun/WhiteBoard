//
//  RequestResult.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestResult : NSObject
/***/
@property (nonatomic, copy) NSString *msg;
/***/
@property (nonatomic, copy) NSString *op;
/***/
@property (nonatomic, copy) NSString *result;
/***/
@property (nonatomic, strong) NSDictionary *data;
/***/
//@property (nonatomic, strong) NSArray *data;
/***/
@property (nonatomic, copy) NSString *type;
@end
