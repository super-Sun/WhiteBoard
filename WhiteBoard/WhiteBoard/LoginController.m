//
//  LoginController.m
//  WhiteBoard
//
//  Created by sunluwei on 16/12/20.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "LoginController.h"

@interface LoginController ()
@property (weak, nonatomic) IBOutlet UITextField *txtName;
@property (weak, nonatomic) IBOutlet UITextField *txtPasswod;
@property (weak, nonatomic) IBOutlet UITextField *txtServer;
@property (weak, nonatomic) IBOutlet UITextField *txtPort;

@end

@implementation LoginController




- (IBAction)btnLoginClick:(UIButton *)sender {
    
    NSString *username = self.txtName.text;
    NSString *password = self.txtPasswod.text;
    
    NSString *server = self.txtServer.text;
    NSString *port = self.txtPort.text;
    NSLog(@"%@---%@",server, port);

    if (username && password && server && port) {
        
        //
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:[username stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_username"];
        [userDefault setObject:[password stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_password"];
        [userDefault setObject:[server stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_server"];
        [userDefault setObject:[port stringByReplacingOccurrencesOfString:@" " withString:@""] forKey:@"wb_port"];
        [userDefault setObject:@"NO" forKey:@"wb_login"];
        [userDefault setObject:@"NO" forKey:@"wb_inmeeting"];
        
        [userDefault synchronize];          
    }
    
    
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
