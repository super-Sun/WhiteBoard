//
//  SCMemberHeadView.h
//  base64code
//
//  Created by sunluwei on 16/12/26.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCMemberHeadView : UIView

/**
 *  创建headview
 *
 *  @return headview实例
 */
+ (instancetype)instanceView;
/**
 *  内容填充
 *
 *  @param title      标题
 *  @param creater    创建者
 *  @param createTime 创建时间
 *  @param count      成员人数
 */
- (void)viewWithTitle:(NSString *)title creater:(NSString *)creater createTime:(NSString *)createTime memberCount:(NSString *)count;

@end
