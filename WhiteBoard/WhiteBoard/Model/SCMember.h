//
//  SCMember.h
//  WhiteBoard
//
//  Created by sunluwei on 16/12/26.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCMember : NSObject

/***/
@property (nonatomic, copy) NSString *message;
/***/
@property (nonatomic, copy) NSString *op;
/***/
@property (nonatomic, copy) NSString *result;
/***/
@property (nonatomic, strong) NSArray *data;


@end
