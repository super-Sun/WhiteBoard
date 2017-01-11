//
//  ViewController.m
//  WhiteBoard
//
//  Created by sunluwei on 16/11/10.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"
#import "AwesomeMenu.h"
#import "AwesomeMenuItem.h"
#import "UIView+AutoLayout.h"
#import "ConnectTool.h"
#import "Draw.h"
#import "HandleImageView.h"
#import "GZIP.h"
#import "ToolView.h"
#import "SCMemberHeadView.h"
#import "Meeting.h"
#import "Account.h"
#import "MBProgressHUD+MJ.h"
#import "FileListController.h"


@interface ViewController () <UIImagePickerControllerDelegate,handleImageViewDelegate, DrawViewDelegate, ToolViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet DrawView *drawView;

@property (nonatomic, strong)ConnectTool *client;

@property (nonatomic, strong) UIButton *curSelectedBtn;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UITableView *memberView;

@property (nonatomic, strong) AwesomeMenu *menu;

@property (nonatomic, strong) ToolView *toolView;

@property (nonatomic, strong) NSArray *accList;

@property (nonatomic, strong) SCMemberHeadView *headView;

@property (nonatomic, strong) Meeting *meeting;

@property (nonatomic, strong) NSArray *members;

@property (nonatomic, assign) int moveLength;

@property (nonatomic, assign) BOOL isShow;
/**存放截图*/
@property (nonatomic, strong) NSMutableArray *imgArray;


@end

@implementation ViewController


- (NSMutableArray *)imgArray {
    if (!_imgArray) {
        self.imgArray = [NSMutableArray array];
        
        [self.imgArray addObject:[self getImage]];
        
    }
    return _imgArray;
    
}

- (NSArray *)members {
    if (!_members) {
        self.members = [NSArray array];
    }
    return _members;
}

- (ToolView *)toolView {
    if (!_toolView) {
        
//        UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
//        UIVisualEffectView * effe = [[UIVisualEffectView alloc]initWithEffect:blur];
//        effe.frame = CGRectMake(0, 0, 210, 160);
        //effe.center = self.view.center;
        //
        self.toolView = [ToolView instanceToolView];
        self.toolView.frame = CGRectMake(0, 0, 200, 150);
        self.toolView.center = self.view.center;
        
        self.toolView.layer.borderWidth = 2;
        
        self.toolView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        NSLog(@"%@", NSStringFromCGRect(self.view.frame));
        
        self.toolView.delegate = self;
        
//        [effe addSubview:self.toolView];
        
        [self.view addSubview: self.toolView];
        
        [self.toolView hideView:YES];
        
    }
    return _toolView;
}





/**
 *  从view上截图
 *
 *  @return 图片
 */
- (UIImage *)getImage {
    
    UIGraphicsBeginImageContextWithOptions(self.scrollView.frame.size, NO, 1.0);  //NO，YES 控制是否透明
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // 生成后的image
    
    return image;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
    
    [self setTableView];
    //初始化状态栏
    [self setupNav];
    
    //scrollView配置
    [self initScrollView];
    
    //创建一个菜单
    [self setupUserMenu];
    
    ConnectTool *client =  [ConnectTool sharedInstance];
    self.client = client;
     
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"DidReceiveDataFromSever"
                                               object:nil];
    //DidReceivePageChangeFromSever
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageChange:)
                                                 name:@"DidReceivePageChangeFromSever"
                                               object:nil];
    

}

/**
 *  接收页面切换信息
 *
 *  @param info 信息 key:"pageNum"
 */
- (void)pageChange:(NSNotification *)info {
    
    NSDictionary *infoDict = [info userInfo];
    
    
    NSNumber *pageNum = infoDict[@"pageNum"];
    
    
    [self.drawView pageControlWithPageNum:[pageNum intValue] andControlType:2];
    
}


/**
 *  初始化tableView
 */
- (void)setTableView {
    //加入一个view
    UITableView *memberView = [[UITableView alloc] init];
    memberView.frame = CGRectMake(self.view.bounds.size.width, 0, 320, self.view.bounds.size.height - 44);
    
    memberView.delegate = self;
    
    memberView.dataSource = self;
//    self.scrollView.backgroundColor = [UIColor redColor];
//    self.view.backgroundColor = [UIColor yellowColor];
    self.memberView = memberView;
    
    //创建头部view
    SCMemberHeadView *headView = [SCMemberHeadView instanceView];
    self.headView = headView;
    
    [headView viewWithTitle:@"无会议信息" creater:@"空" createTime:@"" memberCount:@""];
    
    headView.frame = CGRectMake(0, 0, 320, 260)
    ;
    
    self.memberView.tableHeaderView = headView;
    
    [self.view addSubview:memberView];
    
}

/**
 *  初始化scrollView
 */
- (void)initScrollView {
    
    CGRect rectNav = self.navigationController.navigationBar.frame;
    NSLog(@"nav width - %f", rectNav.size.width); // 宽度
    NSLog(@"nav height - %f", rectNav.size.height);   // 高度
    
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    
    scrollView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - rectNav.size.height);
    scrollView.delegate = self;
    

    self.scrollView = scrollView;
    
    
    self.scrollView.minimumZoomScale = 0.2;
    
    self.scrollView.maximumZoomScale = 3.0;
    
    self.scrollView.backgroundColor = [UIColor grayColor];
    
    
    [self initDrawView];
    
    self.scrollView.contentSize = CGSizeMake(self.drawView.bounds.size.width, self.drawView.bounds.size.height);
    
    [self.view addSubview:scrollView];
    
    
    
    
}

/**
 *  创建DrawView
 */
- (void)initDrawView {
    
    DrawView *drawView = [[DrawView alloc] init];
    
    drawView.frame = CGRectMake(0, 0, 1200, 1200);
    
    drawView.backgroundColor = [UIColor whiteColor];
    
    self.drawView = drawView;
    
    self.drawView.delegate = self;
    
    [self.scrollView addSubview:drawView];
    
    
}

//获取数据
-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    //主线程中执行
    NSString *code = [[notification userInfo] objectForKey:@"code"];
    
    if ([code isEqualToString:MSG_PAN]) {
        //画笔
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView setLineColor:draw.color];
        [self.drawView setLineWidth:draw.lineWidth];
        
        [self.drawView drawWithPoints: draw.points andPathID:draw.ObjId];
        
    } else if([code isEqualToString:MSG_CLEAN]) {
        //清屏
        [self.drawView clear];
        
    } else if ([code isEqualToString:MSG_ICON]) {
        //画其他图形
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView setLineColor:draw.color];
        [self.drawView setLineWidth:draw.lineWidth];
        
        [self.drawView iconWithRect:draw.rect andType:draw.type andPathID:draw.ObjId];
    } else if([code isEqualToString:MSG_IMAGE]) {
        //图片信息
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        
        [self.drawView drawImageWithImage:draw.image andPathID:draw.ObjId rect:draw.rect];
        //self.drawView.image = draw.image;
        
    } else if([code isEqualToString:MSG_TEXT]) {
        //添加文字信息
        //1.获取绘图对象
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        //2.调用drawview文字绘制方法
        [self.drawView setLineColor:draw.color];
        [self.drawView drawWithFontText:draw.text andRect:draw.rect andPathID:draw.ObjId];
        
    } else if([code isEqualToString:MSG_LOCCHANGE]) {
        //位置改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconLocalChangeWithPoint:draw.point andPathIDs:draw.ObjIds];
    } else if([code isEqualToString:MSG_SIZECHANGE]) {
        //大小改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconSizeChangeWithRect:draw.rect andPathID:draw.ObjId];
        
    } else if([code isEqualToString:MSG_COLORCHANGE]) {
        //颜色改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconColorChangeWithColor:draw.color andPathIDs:draw.ObjIds];
        
    } else if([code isEqualToString:MSG_WIDTHCHANGE]) {
        //线宽改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconWidthChangeWithWidth:draw.lineWidth andPathIDs:draw.ObjIds];
        
    } else if([code isEqualToString:MSG_TEXTCHANGE]) {
        //文字改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView fontContentChangeWithText:draw.text andPathID:draw.ObjId];
        //MSG_REMOVE_OBJS
    } else if([code isEqualToString:MSG_REMOVE_OBJS]) {
        //移动改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView removePathsWithPathIDs:draw.ObjIds];
        //
    } else if ([code isEqualToString:MSG_MEMBER_LIST]) {
        
        NSArray *accList = [[notification userInfo] objectForKey:@"data"];
        
        self.accList = accList;
        
    } else if ([code isEqualToString:MSG_MEETING_DETAIL]) {
        
        //移动改变通知
        Meeting *meeting = [[notification userInfo] objectForKey:@"data"];
        
        [self.headView viewWithTitle:@"" creater:[NSString stringWithFormat:@"%d", meeting.creator_id] createTime:@"" memberCount:[NSString stringWithFormat:@"%lu", meeting.members.count]];
        
        self.members = meeting.members;
        
        [self.memberView reloadData];
        
    } else if ([code isEqualToString:@"join_success"]) {
        
       dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showSuccess:@"会议加入成功!"];
       });
        
        
    } else if ([code isEqualToString:MSG_EDITPAGE]) {
        
        
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        
        [self.drawView pageControlWithPageNum:draw.pageNum andControlType:draw.pageControlType];
        
        if (draw.pageControlType == 1) {
            [self.imgArray addObject:[self getImage]];
        }
        
    }
    
    
}
- (void)pan:(UIPanGestureRecognizer *)pan {
    
    CGPoint transP = [pan translationInView:pan.view];
    pan.view.transform = CGAffineTransformTranslate(pan.view.transform, transP.x, transP.y);
    
    //复位
    [pan setTranslation:CGPointZero inView:pan.view];
    
}
/**
 *  初始化状态栏
 */
- (void)setupNav {
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
}
- (BOOL)prefersStatusBarHidden {
    //    [super prefersStatusBarHidden];
    return NO;
}

#pragma mark-tableview delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}
#pragma mark-tableview datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.members.count;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Account *account = self.members[indexPath.row];
    
    static NSString *cellID = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    cell.textLabel.text = account.uname;
    
    cell.imageView.image = [UIImage imageNamed:@"btn_img_pre"];
    
    return cell;
    
    
}




#pragma mark - 实现这个方法来控制屏幕方向
///**
// *  控制当前控制器支持哪些方向
// *  返回值是UIInterfaceOrientationMask*
// */
//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskLandscape;
//}


#pragma mark - Path菜单
/**
 *  创建一个Path菜单item
 */
- (AwesomeMenuItem *)itemWithContent:(NSString *)content highlightedContent:(NSString *)highlightedContent
{
    UIImage *itemBg = [UIImage imageNamed:@"bg_pathMenu_black_normal"];
    return [[AwesomeMenuItem alloc] initWithImage:itemBg
                                 highlightedImage:nil
                                     ContentImage:[UIImage imageNamed:content]
                          highlightedContentImage:[UIImage imageNamed:highlightedContent]];
}

/**
 *  用户菜单
 */
- (void)setupUserMenu
{
    // 1.周边的item
    AwesomeMenuItem *mineItem = [self itemWithContent:@"btn_pen" highlightedContent:@"btn_pen"];
    AwesomeMenuItem *collectItem = [self itemWithContent:@"btn_line" highlightedContent:@"btn_line"];
    AwesomeMenuItem *scanItem = [self itemWithContent:@"btn_eraser" highlightedContent:@"btn_eraser"];
//    AwesomeMenuItem *moreItem = [self itemWithContent:@"icon_pathMenu_more_normal" highlightedContent:@"icon_pathMenu_more_highlighted"];
    NSArray *items = @[mineItem, collectItem, scanItem];
    
    // 2.中间的开始tiem
    AwesomeMenuItem *startItem = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"btn_tool_guanbi"]
                                                       highlightedImage:[UIImage imageNamed:@"btn_tool_guanbi"]
                                                           ContentImage:[UIImage imageNamed:@"btn_tool"]
                                                highlightedContentImage:[UIImage imageNamed:@"btn_tool"]];
    
  
    AwesomeMenu *menu = [[AwesomeMenu alloc] initWithFrame:CGRectZero startItem:startItem optionMenus:items];
    
    self.menu = menu;
    
    [self.view addSubview:menu];
   
    // 约束
    CGFloat menuH = 200;
    [menu autoSetDimensionsToSize:CGSizeMake(200, menuH)];
    [menu autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [menu autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    
    // 3.添加一个背景
    UIImageView *menuBg = [[UIImageView alloc] init];
    menuBg.image = [UIImage imageNamed:@"icon_pathMenu_background"];
    [menu insertSubview:menuBg atIndex:0];
    // 约束
    [menuBg autoSetDimensionsToSize:menuBg.image.size];
    [menuBg autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
    [menuBg autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:0];
    
    // 起点
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    CGFloat margin = 20;
    //menu.startPoint = CGPointMake(screenH - 20, screenW - 20);
    // 起点
    menu.startPoint = CGPointMake(menuBg.image.size.width + margin, menuH - menuBg.image.size.height * 0.5);
    // 禁止中间按钮旋转
    menu.rotateAddButton = NO;
    //设置旋转角度
    menu.rotateAngle = 0.0;
    //设置总体所占角度
    menu.menuWholeAngle = -M_PI_2;
    //设置“添加”按钮和菜单项之间的距离
    menu.farRadius = 100.0f;
    menu.nearRadius = 100.0f;
    menu.endRadius = 100.0f;
    
    // 设置代理
    menu.delegate = self;
}

#pragma mark - 菜单代理
- (void)awesomeMenuWillAnimateClose:(AwesomeMenu *)menu
{
    // 恢复图片
    menu.contentImage = [UIImage imageNamed:@"btn_tool"];
    menu.highlightedContentImage = [UIImage imageNamed:@"btn_tool"];
}

- (void)awesomeMenuWillAnimateOpen:(AwesomeMenu *)menu
{
    // 显示xx图片
    menu.contentImage = [UIImage imageNamed:@"btn_tool_guanbi"];
    menu.highlightedContentImage = [UIImage imageNamed:@"btn_tool_guanbi"];
}

- (void)awesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx
{
    NSLog(@"didSelectIndex-%ld", (long)idx);
    if (idx == 0) {
        //铅笔－－绘图
        [self.drawView setLineColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    } else if(idx == 1) {
        //菜单－－选择颜色和粗细
        
        [self.toolView hideView:NO];
        
        
    } else if(idx == 2) {
        //橡皮
        [self.drawView erase];
    }
    
    [self awesomeMenuWillAnimateClose:menu];
}

#pragma mark-ToolViewDelegate-
- (void)toolViewColorSelected:(ToolView *)toolView color:(UIColor *)color {
    [self.drawView setLineColor:color];
    
}

- (void)toolViewlineHeightSelected:(ToolView *)toolView lineHeight:(CGFloat)lineWidth {
    
    [self.drawView setLineWidth:lineWidth];
}

#pragma mark-DrawViewDelegate-
- (void)panDrawView:(DrawView *)drawView andData:(NSData *)data{
    //拿到绘制的点坐标集合
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *isLogin = [userDefault objectForKey:@"wb_login"];
    NSString *isMeeting = [userDefault objectForKey:@"wb_inmeeting"];
    
    if ([isLogin isEqualToString:@"YES"] && [isMeeting isEqualToString:@"YES"]) {
        //
        NSLog(@"%@",data);
        [self.client sendWhiteData:data];
    } else {
        NSLog(@"nononononononnonononononononono");
    }
    
    
    
}


#pragma mark-scrollView缩放
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    
    
    
    return self.drawView;
    
    
    
}




- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    
    NSLog(@"scale:%f", scale);
    CGFloat offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width)?
    
    (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height)?
    
    (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0;
    
    self.drawView.center = CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX,
                                       
                                       self.scrollView.contentSize.height * 0.5 + offsetY);
    

    
    
    
}


#pragma mark-导航栏按钮点击操作
/**
 *  按钮点击切换效果
 *
 *  @param sender 点击的按钮
 */
- (void)buttonStateChangeWithButton:(UIButton *)sender {
    
    if (sender.isSelected) {
        return;
    }
    
    self.curSelectedBtn.selected = NO;
    self.curSelectedBtn.backgroundColor = [UIColor clearColor];
    
    sender.selected = YES;
    
//    sender.backgroundColor = [UIColor colorWithRed:33 / 255.0 green:39 / 255.0 blue:41 / 255.0 alpha:1];
    
    self.curSelectedBtn = sender;
    
}


- (CGRect)rectMoveWithFrame:(CGRect)frame length:(CGFloat)lenght {
    CGRect rect = frame;
    rect.origin.x = frame.origin.x - lenght;
    
    return rect;
}

- (void)messageBack {
    
    if (!self.isShow) {
        return;
    }
    
    self.isShow = !self.isShow;
    
    self.moveLength = -320;
    
    [UIView animateWithDuration:0.5 animations:^{
        
        //移动memberview 320
        self.memberView.frame = [self rectMoveWithFrame:self.memberView.frame length:self.moveLength];
        
        //移动drawView
        
        //self.drawView.frame = [self rectMoveWithFrame:self.drawView.frame length:self.moveLength];
        
        //移动menu
        self.menu.frame = [self rectMoveWithFrame:self.menu.frame length:self.moveLength];
        self.scrollView.frame = [self rectMoveWithFrame:self.scrollView.frame length:self.moveLength];
        
    }];
    
}


/**
 *  消息按钮点击
 *
 *  @param sender
 */
- (IBAction)btnMessage:(UIButton *)sender {
    
    if (self.isShow) {
        
        self.moveLength = -320;
        
        sender.selected = NO;
        
        self.menu.userInteractionEnabled = YES;
        
        
    } else {
        //
        
        self.menu.userInteractionEnabled = NO;
        
        self.moveLength = 320;
        
        [self.drawView addRecognizer];
        
        [self.client queryMember];

    }
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    self.isShow = !self.isShow;
    
    
    [UIView animateWithDuration:0.5 animations:^{
        
        //移动memberview 320
        self.memberView.frame = [self rectMoveWithFrame:self.memberView.frame length:self.moveLength];
        
        //移动drawView
        
        //self.drawView.frame = [self rectMoveWithFrame:self.drawView.frame length:self.moveLength];
        
        //移动menu
        self.menu.frame = [self rectMoveWithFrame:self.menu.frame length:self.moveLength];
        self.scrollView.frame = [self rectMoveWithFrame:self.scrollView.frame length:self.moveLength];

    }];
    
}



/**
 *  文件按钮点击
 *
 *  @param sender
 */
- (IBAction)btnFiles:(UIButton *)sender {
    
    
//    [MBProgressHUD showError:@"暂不可用!"];
    
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    //modal Files 控制器
    FileListController *flc = [[FileListController alloc] init];

//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:flc];
    
    
    
    [self presentViewController:flc animated:YES completion:^{
        NSLog(@"弹出一个模态窗口");
        
        [flc setDataWithArray:[self.imgArray copy]];
        
    }];
    
    
    
    
}

/**
 *  图片按钮点击
 *
 *  @param sender
 */
- (IBAction)btnImage:(UIButton *)sender {
    
    [self messageBack];
    
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    //从系统相册当中选择一张图片
    //1.弹出系统相册
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    
    //设置照片的来源
    pickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pickerVC.delegate = self;
    //modal出系统相册
    [self presentViewController:pickerVC animated:YES completion:nil];

    
    
}
/**
 *  屏幕手势支持
 *
 *  @param sender sender        
 */
- (IBAction)btnScrollable:(UIButton *)sender {
    
    if (!sender.isSelected) {
        
        self.drawView.userInteractionEnabled = NO;
        
    } else {
        
        self.drawView.userInteractionEnabled = YES;
        
    }
    
    //按钮状态改变
    sender.selected = !sender.selected;
    
    
    
    
}


/**
 *  截屏
 *
 *  @param sender sender
 */
- (IBAction)btnScreenshot:(UIButton *)sender {
    
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    //1.获取当前白板页码
    //2.生成截图
    //3.更改self.imgArray对应的图片
    int pageNum = [self.drawView getCurrentPageNum];
    
    UIImage *newImage = [self getImage];
    
    [self.imgArray replaceObjectAtIndex:pageNum withObject:newImage];
    [self screenAnimate];
    
}

/**
 *  屏闪动画
 */
- (void)screenAnimate {
    
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.backgroundColor = [UIColor blackColor];
    
    
    [self.view addSubview:view];
    
    [UIView animateWithDuration:0.15 animations:^{
        
        view.alpha = 0;
        
    } completion:^(BOOL finished) {

        [view removeFromSuperview];
        
    }];
    
    
}






/**
 *  添加按钮点击
 *
 *  @param sender
 */
- (IBAction)btnAdd:(UIButton *)sender {
    
//    [MBProgressHUD showError:@"暂不可用!"];
    
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    
    //获取当前白板页数
    int pageNum = [self.drawView getPageNum];
    //添加白板页
    [self.drawView pageControlWithPageNum:pageNum andControlType:1];
    
    
    [self.imgArray addObject:[self getImage]];

    
    [self.client pageControlWithPageNum:(char)pageNum andControlType:1];
    
    
}
/**
 *  删除按钮点击
 *
 *  @param sender
 */
- (IBAction)btnDelete:(UIButton *)sender {
    
//    [MBProgressHUD showError:@"暂不可用!"];
    
    
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    
    int currentPage = [self.drawView getCurrentPageNum];

    [self.drawView clear];
    
    [self.client cleanPageWithPageNum:currentPage];
    
    
}
/**
 *  撤销按钮点击
 *
 *  @param sender
 */
- (IBAction)btnRevoke:(UIButton *)sender {
    //按钮状态改变
    [self buttonStateChangeWithButton:sender];
    
    [self.drawView undo];
    
}

- (void)sendImage:(UIImage *)image andRect:(CGRect)rect{
    
    NSData *originalData = UIImageJPEGRepresentation(image, 1.0);
    NSData *zipdata0 = UIImageJPEGRepresentation(image, 0.2);;
    
    NSData *zipData = [zipdata0 customerGzippedData];
    
    
    struct ImageDraw pan;
    //结构体内-清空多余空间
    memset(&pan, 0, sizeof(struct ImageDraw));
    
    pan.commondID = 3;
    pan.pageID = arc4random();
    pan.ObjId = 0;
    pan.ObjType = 9;
    
    /**对象ID*/
    pan.ObjID = pan.pageID;
    
    pan.dwSize = (int)zipData.length;
    pan.dwUnSize = (int)zipdata0.length;
    
    /**对象位置*/
    pan.rcRect.left = 0;
    pan.rcRect.top = 0;
    pan.rcRect.right = rect.size.width;
    pan.rcRect.bottom = rect.size.height;
    
    
    /**数据大小*/
    pan.dwDataSize = (int)zipData.length + 28;
    //用结构体去接收data数据
    NSData *datapre = [NSData dataWithBytes:&pan length:48];
    
    NSMutableData *mudata = [NSMutableData data];
    [mudata appendData:datapre];
    [mudata appendData:zipData];
    
    
    [self.drawView drawImageWithImage:image andPathID:pan.ObjID rect:rect];
    
    [self.client sendWhiteData:mudata];
}

- (void)sendImageWithData:(NSData *)data {
    
    NSData *zipData = [data customerGzippedData];
    
    //[self.client sendWhiteData:];
    
    struct ImageDraw pan;
    //结构体内-清空多余空间
    memset(&pan, 0, sizeof(struct ImageDraw));
    
    pan.commondID = 3;
    pan.pageID = arc4random();
    pan.ObjId = 0;
    pan.ObjType = 9;
    
    /**对象ID*/
    pan.ObjID = pan.pageID;
    
    pan.dwSize = (int)zipData.length;
    pan.dwUnSize = 438;
 
    /**对象位置*/
    pan.rcRect.left = 0;
    pan.rcRect.top = 0;
    pan.rcRect.right = 16;
    pan.rcRect.bottom = 12;
    
    
    /**数据大小*/
    pan.dwDataSize = (int)zipData.length + 28;
    //用结构体去接收data数据
    NSData *datapre = [NSData dataWithBytes:&pan length:48];

    NSMutableData *mudata = [NSMutableData data];
    [mudata appendData:datapre];
    [mudata appendData:zipData];
    
    [self.client sendWhiteData:mudata];
}

//当选择某一个照片时,会调用这个方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSLog(@"%@",info);
    UIImage *image  = info[UIImagePickerControllerOriginalImage];
    
//    NSData *zipdata = UIImageJPEGRepresentation(image, 1.0);
    NSData *zipdata = [NSData dataWithContentsOfFile:@"/Users/sunluwei/Desktop/img.jpg"];
    
    //[self sendImage:image];
    
    //NSData *data = UIImageJPEGRepresentation(image, 1);
    NSData *data = UIImagePNGRepresentation(image);
    //[data writeToFile:@"/Users/xiaomage/Desktop/photo.jpg" atomically:YES];
//    [data writeToFile:@"/Users/sunluwei/Desktop/photo.png" atomically:YES];
    
    HandleImageView *handleV = [[HandleImageView alloc] init];
    handleV.backgroundColor = [UIColor clearColor];
    handleV.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    handleV.image = image;
    handleV.delegate = self;
    [self.view addSubview:handleV];
    
    
    //self.drawView.image = image;
    //取消弹出的系统相册
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (void)handleImageView:(HandleImageView *)handleImageView newImage:(UIImage *)newImage {

    NSLog(@"rect:%@",NSStringFromCGRect(handleImageView.ImgRect));
    
    [self sendImage:newImage andRect:handleImageView.ImgRect];
    
    
}


/**
 *  释放该释放的
 */
- (void)dealloc {
    
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
