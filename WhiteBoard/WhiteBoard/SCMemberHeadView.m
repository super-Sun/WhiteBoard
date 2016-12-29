//
//  SCMemberHeadView.m
//  base64code
//
//  Created by sunluwei on 16/12/26.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "SCMemberHeadView.h"

@interface SCMemberHeadView ()

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;

@property (weak, nonatomic) IBOutlet UILabel *lblCreater;

@property (weak, nonatomic) IBOutlet UILabel *lblStartTime;

@property (weak, nonatomic) IBOutlet UILabel *lblMemberCount;

@end


@implementation SCMemberHeadView

+ (instancetype)instanceView {
    
    NSArray* nibView =  [[NSBundle mainBundle] loadNibNamed:@"SCMemberHeadView" owner:nil options:nil];
    
    return [nibView firstObject];
    
}

- (void)viewWithTitle:(NSString *)title creater:(NSString *)creater createTime:(NSString *)createTime memberCount:(NSString *)count{
    
    self.lblTitle.text = title;
    self.lblCreater.text = creater;
    self.lblStartTime.text = createTime;
    self.lblMemberCount.text = count;

}


@end
