//
//  FileListController.m
//  WhiteBoard
//
//  Created by sunluwei on 17/1/11.
//  Copyright © 2017年 scooper. All rights reserved.
//

#import "FileListController.h"
#import "PhotoCell.h"
#import "FlowLayout.h"

@interface FileListController ()<UICollectionViewDataSource, UICollectionViewDelegate>


@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, weak) UICollectionView *collectionView;


@end

@implementation FileListController


- (void)setDataWithArray:(NSArray *)dataArray {
    
    _dataArray = dataArray;
    
    [self.collectionView reloadData];
    
    
}

#define ScreenW [UIScreen mainScreen].bounds.size.width
static NSString * const ID = @"cell";
// 函数式编程思想(高聚合):把很多功能放在一个函数块(block块)去处理
// 编程思想:低耦合,高聚合(代码聚合,方便去管理)
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"白板列表";
    self.view.backgroundColor = [UIColor blackColor];
    // Do any additional setup after loading the view, typically from a nib.
    // 利用布局就做效果 => 如何让cell尺寸不一样 => 自定义流水布局
    // 流水布局:调整cell尺寸
    FlowLayout *layout = ({
        
        FlowLayout *layout = [[FlowLayout alloc] init];
        
        // 设置尺寸
        layout.itemSize = CGSizeMake(150, 150);
        
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        CGFloat margin = (ScreenW - 150) * 0.5;
        layout.sectionInset = UIEdgeInsetsMake(0, margin, 0, margin);
        // 设置最小行间距
        layout.minimumLineSpacing = 50;
        layout;
        
    });
    
    // 创建UICollectionView:黑色
    UICollectionView *collectionView = ({
        
        UICollectionView *collectionView =  [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.backgroundColor = [UIColor brownColor];
        collectionView.center = self.view.center;
        collectionView.bounds = CGRectMake(0, 0, self.view.bounds.size.width, 250);
        collectionView.showsHorizontalScrollIndicator = NO;
        [self.view addSubview:collectionView];
        
        // 设置数据源
        collectionView.dataSource = self;
        
        collectionView.delegate = self;
        
        collectionView;
        
    });
    
    self.collectionView = collectionView;
    
    // 注册cell
    [collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([PhotoCell class])  bundle:nil] forCellWithReuseIdentifier:ID];
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ID forIndexPath:indexPath];
    
    cell.image = self.dataArray[indexPath.row];
    
    cell.title = [NSString stringWithFormat:@"第%lu页", indexPath.row + 1];
    
//    NSString *imageName = [NSString stringWithFormat:@"%ld",indexPath.item + 1];
//    
//    cell.image = [UIImage imageNamed:imageName];
    
    return cell;
}
#pragma mark-UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"%lu", indexPath.row);
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"移除");
        
        
        NSNumber *selectedPage = [NSNumber numberWithInteger:indexPath.row];
        
        NSDictionary *dict = @{@"pageNum" : selectedPage};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceivePageChangeFromSever" object:nil userInfo:dict];
        
    }];
    
    
    
    
}



@end
