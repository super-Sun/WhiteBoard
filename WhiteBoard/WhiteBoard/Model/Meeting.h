//
//  Meeting.h
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Meeting : NSObject <NSCopying>
/**会议ID*/
@property (nonatomic, copy) NSString *meeting_id;
/**会议名称*/
@property (nonatomic, copy) NSString *meeting_name;
/**创建者id*/
@property (nonatomic, assign) int creator_id;

/**会议成员*/
@property (nonatomic, strong) NSArray *members;

@end
