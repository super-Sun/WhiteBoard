//
//  ViewController.m
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "ViewController.h"
#import "DrawView.h"
#import "HandleImageView.h"
#import "ConnectTool.h"
#import "Draw.h"
#import "SCRect.h"

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,handleImageViewDelegate>
@property (weak, nonatomic) IBOutlet DrawView *drawView;

@property (nonatomic, strong)ConnectTool *client;

@end

@implementation ViewController

//属于谁的东西,应该在谁里面去写.
//清屏
- (IBAction)clear:(id)sender {
    [self.drawView clear];
    [self.client joinMeetingWithMID:@""];
}

//撤销
- (IBAction)undo:(id)sender {
    [self.drawView undo];
}

//橡皮擦
- (IBAction)erase:(id)sender {
    [self.drawView erase];
}

//设置线的宽度
- (IBAction)setLineWidth:(UISlider *)sender {
    [self.drawView setLineWidth:sender.value];
}

//设置线的颜色
- (IBAction)setLineColor:(UIButton *)sender {
    [self.drawView setLineColor:sender.backgroundColor];
}


//照片
- (IBAction)photo:(id)sender {
    //从系统相册当中选择一张图片
    //1.弹出系统相册
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    
    //设置照片的来源
    pickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    pickerVC.delegate = self;
    //modal出系统相册
    [self presentViewController:pickerVC animated:YES completion:nil];
}


//保存
- (IBAction)save:(id)sender {
    //把绘制的东西保存到系统相册当中
    
    //1.开启一个位图上下文
    UIGraphicsBeginImageContextWithOptions(self.drawView.bounds.size, NO, 0);
    
    
    //2.把画板上的内容渲染到上下文当中
    CGContextRef ctx =  UIGraphicsGetCurrentContext();
    [self.drawView.layer renderInContext:ctx];
    
    //3.从上下文当中取出一张图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    //4.关闭上下文
    UIGraphicsEndImageContext();
    
    //5.把图片保存到系统相册当中
    //注意:@selector里面的方法不能够瞎写,必须得是image:didFinishSavingWithError:contextInfo:
    UIImageWriteToSavedPhotosAlbum(newImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    
    
}

//保存完毕时调用
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"success");
    
}
//- (void)saveSuccess {
//    NSLog(@"success");
//}




- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *test = @"slw'你";
    NSUInteger bytes = [test lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"%ld bytes", bytes);

    NSLog(@"%ld", test.length);
    
    
    // Do any additional setup after loading the view, typically from a nib
    ConnectTool *client =  [ConnectTool sharedInstance];
    self.client = client;
    client.host = @"192.168.100.15";
    client.port = 80;
    [client connectToServer];
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"DidReceiveDataFromSever"
                                               object:nil];
    
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
        UIImage *image = [[notification userInfo] objectForKey:@"data"];
        //self.drawView.image = image;
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
        //大小改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconColorChangeWithColor:draw.color andPathIDs:draw.ObjIds];
        
    } else if([code isEqualToString:MSG_WIDTHCHANGE]) {
        //大小改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView iconWidthChangeWithWidth:draw.lineWidth andPathIDs:draw.ObjIds];
        
    } else if([code isEqualToString:MSG_TEXTCHANGE]) {
        //文字改变通知
        Draw *draw = [[notification userInfo] objectForKey:@"data"];
        [self.drawView fontContentChangeWithText:draw.text andPathID:draw.ObjId];
        
    }

    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


//当选择某一个照片时,会调用这个方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {

    NSLog(@"%@",info);
    UIImage *image  = info[UIImagePickerControllerOriginalImage];

    //NSData *data = UIImageJPEGRepresentation(image, 1);
    NSData *data = UIImagePNGRepresentation(image);
    //[data writeToFile:@"/Users/xiaomage/Desktop/photo.jpg" atomically:YES];
    [data writeToFile:@"/Users/xiaomage/Desktop/photo.png" atomically:YES];
    
    HandleImageView *handleV = [[HandleImageView alloc] init];
    handleV.backgroundColor = [UIColor clearColor];
    handleV.frame = self.drawView.frame;
    handleV.image = image;
    handleV.delegate = self;
    [self.view addSubview:handleV];
    
    
    //self.drawView.image = image;
    //取消弹出的系统相册 
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}


-(void)handleImageView:(HandleImageView *)handleImageView newImage:(UIImage *)newImage {
    
    self.drawView.image = newImage;
    
}



- (void)pan:(UIPanGestureRecognizer *)pan {
    
    CGPoint transP = [pan translationInView:pan.view];
    pan.view.transform = CGAffineTransformTranslate(pan.view.transform, transP.x, transP.y);
    
    //复位
    [pan setTranslation:CGPointZero inView:pan.view];
    
}

- (void)pinch:(UIPinchGestureRecognizer *)pinch {
    
    pinch.view.transform = CGAffineTransformScale(pinch.view.transform, pinch.scale,pinch.scale);
    
    [pinch setScale:1];
    
}

//- (void)longP:(UILongPressGestureRecognizer *)longP {
//    
//    if (longP.state == UIGestureRecognizerStateBegan) {
//        
//        //先让图片闪一下,把图片绘制到画板当中
//        [UIView animateWithDuration:0.5 animations:^{
//           longP.view.alpha = 0;
//        }completion:^(BOOL finished) {
//            
//           [UIView animateWithDuration:0.5 animations:^{
//               longP.view.alpha = 1;
//               
//           }completion:^(BOOL finished) {
//               
//               //把图片绘制到画板当中
//               
//               UIGraphicsBeginImageContextWithOptions(longP.view.bounds.size, NO, 0);
//               CGContextRef ctx = UIGraphicsGetCurrentContext();
//               [longP.view.layer renderInContext:ctx];
//               
//            
//               UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//               UIGraphicsEndImageContext();
//               
//               self.drawView.image = newImage;
//               
//               //[longP.view removeFromSuperview];
//               
//
//           }];
//            
//        }];
//        
//        
//    }
//}









@end
