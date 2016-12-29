//
//  Meeting.m
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "Meeting.h"

@implementation Meeting

//实现NSCopying协议的方法，来使此类具有copy功能
- (instancetype)copyWithZone:(NSZone *)zone
{
    Meeting *newMeeting = [[Meeting allocWithZone:zone] init];
    
    newMeeting.creator_id = self.creator_id;
    
    newMeeting.meeting_name = self.meeting_name;
    
    newMeeting.members = self.members;
    
    newMeeting.meeting_id = self.meeting_id;
    
    return newMeeting;
}



@end
