//
//  PhotoCell.m
//  自定义流水布局
//
//  Created by xiaomage on 16/3/9.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell ()
@property (weak, nonatomic) IBOutlet UILabel *pageLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@end

@implementation PhotoCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    
    _photoView.image = image;
    
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    
    self.pageLabel.text = title;
    
    
}

@end
