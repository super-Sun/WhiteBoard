//
//  LoginController.m
//  WhiteBoard
//
//  Created by sunluwei on 16/12/20.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "LoginController.h"
#import "ConnectTool.h"
#import "ViewController.h"
#import "MBProgressHUD+MJ.h"

@interface LoginController ()
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtPasswod;
@property (weak, nonatomic) IBOutlet UITextField *txtServer;
@property (weak, nonatomic) IBOutlet UITextField *txtPort;

@property (nonatomic, weak) MBProgressHUD *hd;

@property (nonatomic, strong) ViewController *vc;

@end
static NSString *isLogin = @"NO";

static BOOL isConnected = NO;

@implementation LoginController




- (IBAction)btnLoginClick:(UIButton *)sender {
    
    
    
    
    
    
//    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    
    
    self.hd = [MBProgressHUD showMessage:@"login..." toView:self.view];
    
        
    
    NSString *username = self.txtName.text;
    NSString *password = self.txtPasswod.text;
    
    NSString *server = self.txtServer.text;
    NSString *port = self.txtPort.text;
    
    NSLog(@"%@---%@",server, port);

    if (username && password && server && port) {
        
        //
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        
        
        
        
        [self login];
        
        
        
    }
    
    
}

- (void)login {
    
    
    ConnectTool *client =  [ConnectTool sharedInstance];
    //self.client = client;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    
    if ([isLogin isEqualToString:@"YES"]) {
        
        [self.hd removeFromSuperview];
        
        
        [MBProgressHUD showSuccess:@"登录成功！"];
        //push
        
        
        [self pushViewController];
        
        return;
    } else {
        NSString *username = self.txtName.text;
        NSString *password = self.txtPasswod.text;
        
        NSString *server = self.txtServer.text;
        NSString *port = self.txtPort.text;
        
        [userDefaults setObject:[username stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_username"];
        [userDefaults setObject:[password stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_password"];
        [userDefaults setObject:[server stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_server"];
        [userDefaults setObject:[port stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_port"];
        [userDefaults setObject:@"NO" forKey:@"wb_login"];
        [userDefaults setObject:@"NO" forKey:@"wb_inmeeting"];
        
        [userDefaults synchronize];
        
        
        
        
    }
    
    
    [self connected];
    
    [client loginWithUserName:[userDefaults objectForKey:@"wb_username"] password:[userDefaults objectForKey:@"wb_password"]];
    
    //注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"DidReceiveLoginDataFromSever"
                                               object:nil];
    
    
    
}

- (void)connected {
    NSString *username = self.txtName.text;
    NSString *password = self.txtPasswod.text;
    
    NSString *server = self.txtServer.text;
    NSString *port = self.txtPort.text;
    
    ConnectTool *client =  [ConnectTool sharedInstance];
    
    client.host = server;
    client.port = [port intValue];
    
    if (!isConnected) {
        [client connectToServer];
    }
    
   
    
    
    
    
}

- (void)pushViewController {
    
    if (!self.vc) {
        
        
        UIStoryboard *whiteboard = [UIStoryboard storyboardWithName:@"Whiteboard" bundle:nil];
        ViewController *vc=[whiteboard instantiateViewControllerWithIdentifier:@"vc"];

        
        
        self.vc = vc;
    }
    
    [self.navigationController pushViewController:self.vc animated:YES];
    
    
    
}

-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    
    NSString *login = [[notification userInfo] objectForKey:@"msg"];
    
    if ([login isEqualToString:@"LOGIN_SUCCESS"]) {
        isLogin = @"YES";
        NSLog(@"%@", [NSThread currentThread]);
        
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //
                [self.hd removeFromSuperview];
                
                [MBProgressHUD showSuccess:@"登录成功!"];
                
                [self pushViewController];
            });
            
        });
        
    } else if ([login isEqualToString:@"LOGIN_FAIL"]) {
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //
            NSLog(@"hiba:%@", [NSThread currentThread]);
//            [MBProgressHUD hideHUD];
//            [MBProgressHUD hideHUD];
            [self.hd removeFromSuperview];
            
            [MBProgressHUD showError:@"登录失败"];
        });
        
        
        
        NSLog(@"fail");
        
        
    } else if ([login isEqualToString:@"connect_error"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
           
            [self.hd removeFromSuperview];
            
            [MBProgressHUD showError:@"服务器连接失败"];
        });
        
        
        
        NSLog(@"error");
        
        
    } else if ([login isEqualToString:@"connect_success"]) {
        
        isConnected = YES;
        
    }
    
    NSLog(@"%@", login);
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.txtName.text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
