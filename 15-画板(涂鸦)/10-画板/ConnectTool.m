//
//  ConnectTool.m
//  10-画板
//
//  Created by sunluwei on 16/11/9.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "ConnectTool.h"
#import "GCDAsyncSocket.h"
#import "MJExtension.h"
#import "RequestResult.h"
#import "RequestResultOther.h"
#import "Account.h"
#import "Meeting.h"
#import "InviteMeeting.h"
#import "SIAlertView.h"
#import "Draw.h"
#import "SCPoint.h"
#import "SCRect.h"
#import "zlib.h"


@interface ConnectTool() <GCDAsyncSocketDelegate>
/***/
@property(nonatomic ,strong) GCDAsyncSocket *socket;
/**计时器*/
@property (nonatomic, strong) NSTimer *connectTimer;
/***/
@property (nonatomic, strong) Account *account;
@property (nonatomic, assign) int lastLength;

@property (nonatomic, strong) NSMutableData *muData;

/**会议*/
@property (nonatomic, strong) Meeting *meeting;
/**收到邀请的会议模型*/
@property (nonatomic, strong) InviteMeeting *inviteMeeting;
/**会议成员数组*/
@property (nonatomic, strong) NSArray *members;

@end


@implementation ConnectTool

- (NSMutableData *)muData {
    if (_muData == nil) {
        self.muData = [NSMutableData data];
    }
    return _muData;
}
/**
 *  单例模式
 *
 *  @return <#return value description#>
 */
+(ConnectTool *) sharedInstance
{
    
    static ConnectTool *sharedInstace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstace = [[self alloc] init];
    });
    
    return sharedInstace;
}

/**连接到服务器*/
- (BOOL)connectToServer {
    // 1.与服务器通过三次握手建立连接
    NSString *host = @"192.168.101.15";
    int port = 6888;
    //创建一个socket对象
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    //连接
    NSError *error = nil;
    [self.socket connectToHost:host onPort:port withTimeout:10 error:&error];
    if (error) {
        //无法连接到主机
        NSLog(@"%@，无法连接主机",error);
        return NO;
    }
    NSLog(@"%@",self.socket);
    return YES;
}
/**断开连接*/
- (void)disconnectToServer {
    [self cutOffSocket];
}
/**收到数据的回调*/
- (void)getDataFromServer {
    
}
/**发送数据*/
- (void)sendDataToServer: (NSData *)data {
    [self.socket writeData: data withTimeout:5 tag:0];
}

#pragma mark -socket的代理
#pragma mark 连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%s",__func__);
    NSLog(@"%@",[NSThread currentThread]);
    
    //连接成功后每隔XX秒发送心跳包
    // 每隔 x s像服务器发送心跳包
    // 在longConnectToSocket方法中进行长连接需要向服务器发送的讯息
    self.connectTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    //[[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop mainRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
//    [self.connectTimer fire];
    //用户登录
    [self login];
    
    
    
}
#pragma mark 断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    [self.connectTimer invalidate];
    
    if (err) {
        NSLog(@"连接失败");
        NSLog(@"%@",err);
    }else{
        NSLog(@"正常断开");
        NSLog(@"%@",[NSThread currentThread]);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *string = @"11111";
        NSData *data = [string dataUsingEncoding:kCFStringEncodingUTF8];
        NSDictionary *dictData = @{@"data": data};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
    });
    NSLog(@"sorry the connect is failure %@",sock.userData);
    if (sock.userData == SocketOfflineByServer || sock.userData == nil) {
        // 服务器掉线，重连
        NSLog(@"reconnected...");
        [self connectToServer];
    }
    else if (sock.userData == [[NSNumber alloc] initWithInteger:SocketOfflineByUser]) {
        // 如果由用户断开，不进行重连
        return;
    }
    
    
}
#pragma mark 数据发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%ld数据发送成功",tag);
    //发送完数据手动读取，-1不设置超时
    
    [sock readDataWithTimeout:-1 tag:tag];
    //    [sock readDataWithTimeout:-1 tag:1009];
    
    
}
#pragma mark 读取数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //1.判断data length > 4
    
    //2.
    /**
     *
     
     {
     "data": {
     "token": "5f960dfd-38a5-4749-b085-2b2497fb98a7",
     "uid": 132,
     "uname": "slw"
     },
     "msg": "ok",
     "op": "login",
     "result": "ok"
     }
     
     -----------------
     {
     "data": {
     "from_uid": 1,
     "meeting_id": "d5deda53-e2e8-4bef-a03e-efacc277dd74",
     "wb_data": "AQAAAJKi0HgAAAAA"
     },
     "op": "notify",
     "type": "whiteboard"
     }
     
     */
    
    NSLog(@"%s消息接收成功",__func__);
    if (data.length ==4) {
        //        NSLog(@"data.length%ld",data.length);
        //
        //        NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //        int someInt = [aString intValue];
        //        NSLog(@"length:%d",someInt);
    }
    if (self.lastLength == 0) {
        [self.muData setLength:0];
    }
    if (data.length == 1448) {
        [self.muData appendData:data];
        self.lastLength = 1448;
    } else {
        if (self.lastLength == 1448) {
            [self.muData appendData:data];
            
            data = self.muData;
            
            self.lastLength = 0;
        }
    }
    
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"tag:%ld",tag);
    NSLog(@"data.length:%ld, resultStr:------%@",data.length, receiverStr);
    NSLog(@"resultDict:%@",[self jsonDictWithString:receiverStr]);
    
    //NSLog(@"%s 收到的报文:%@",__func__,receiverStr);
    //获取到数据后发送通知
    
    //切换到主线程中发送
    
    if (receiverStr.length > 4) {
//        dispatch_async(dispatch_get_main_queue(), ^{
        
            //            if (tag == 2016) {//member查询
            //                RequestResultOther *requestMember = [RequestResultOther mj_objectWithKeyValues:receiverStr];
            //                [self initResultData:requestMember];
            //            }
            
        RequestResult *result = [RequestResult mj_objectWithKeyValues:receiverStr];
        
        if (result != nil) {
            //解析不成功
            NSLog(@"result:%@", result.data);
            
            //处理收到的数据
            [self initResultData:result];
        }
            
        
            
            
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
//        });
    }
    
    
}
#pragma mark -socket的代理End-

#pragma mark 用户操作
/**
 *  用户登录
 */
- (void)login {
    //1.获取用户登入的信息
    NSString *username = @"cs";
    NSString *password = @"admin";
    
    NSDictionary *dictParam = @{
                                    @"op":@"login",
                                    @"user":username,
                                    @"pwd":password
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送登陆请求
    [self sendDataToServer:parmData];
    //[self.socket writeData:parmData withTimeout: -1 tag:2001];
    //    [self.socket readDataWithTimeout:-1 tag:2000];
    
    
}
/**
 *  用户登出
 */
- (void)logout {
    //1.获取用户登入的信息
    NSString *op = @"logout";
    NSString *token = self.account.token;
    
    NSDictionary *dictParam = @{@"op":op,@"token":token};
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送登陆请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:3];
}

#pragma mark 白板操作
/**
 *  创建白板会议
 *
 *  @param meetName 会议名称
 *  @param type     会议类型(保留关键字)
 */
- (void)createMeetingWithMeetingName:(NSString *)meetName andMeetType:(int) type {
    
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_CREATE;
    NSString *token = self.account.token;
    
    
    NSDictionary *dictParam = @{@"op":op,@"token":token,@"meeting_name":meetName,@"meeting_type":@0};
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:1003];
    
}
/**
 *  邀请成员加入会议
 *
 *  @param IDs 成员id
 */
- (void)inviteMeetingWithUserIDs:(NSArray *)IDs {
    
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_TYPE_INVITE;
    NSString *token = self.account.token;
    
    NSString *users = [IDs componentsJoinedByString:@","];
    
    NSDictionary *dictParam = @{
                                @"op":op,
                                @"token":token,
                                @"meeting_id":self.meeting.meeting_id,
                                @"users":users
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:1003];
}
/**
 *  拒绝会议
 *
 *  @param reason 拒绝的原因
 */
- (void)refuseMeetingWithReason:(NSString *)reason andMeetingID:(NSString *)meetingID {
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_TYPE_REJECT;
    NSString *token = self.account.token;
    
    NSDictionary *dictParam = @{
                                @"op":op,
                                @"token":token,
                                @"meeting_id":meetingID,
                                @"reason":reason
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:1003];
}
/**
 *  退出会议
 */
- (void)exitCurrentMeeting {
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_TYPE_EXIT;
    NSString *token = self.account.token;
    /**
     *  delete:为保留关键字
     */
    NSDictionary *dictParam = @{
                                @"op":op,
                                @"token":token,
                                @"meeting_id":self.meeting.meeting_id,
                                @"delete":@0
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:1003];
}
/**
 *  指定用户请出会议
 *
 *  @param userId 用户id
 */
- (void)kickoutMeetingWithUserId: (NSString *)userId {
    
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_TYPE_KICKOUT;
    NSString *token = self.account.token;
    
    
    NSDictionary *dictParam = @{
                                @"op":op,
                                @"token":token,
                                @"meeting_id":self.meeting.meeting_id,
                                @"uid":userId
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    //暂定2016为 获取成员对标志位
    [self.socket writeData:parmData withTimeout: -1 tag:2016];
}
/**
 *  查询会议中的成员
 */
- (void)queryMember {
    if ([self interceptor] < 0 ) {
        return;
    }
    
    //1.获取的信息
    NSString *op = NOTIFY_OP_MEMBERS;
    NSString *token = self.account.token;
    
    
    NSDictionary *dictParam = @{
                                @"op":op,
                                @"token":token,
                                @"meeting_id":self.meeting.meeting_id,
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    //3.发送请求
    
    [self.socket writeData:parmData withTimeout: -1 tag:1003];
    
}

/**
 *  权限拦截
 *
 *  @return 拦截结果
 */
- (int)interceptor {
    
    BOOL isSuccess = 1;
    
    if (self.account == nil) {
        NSLog(@"用户信息不存在，先进行登录");
        //return;
        isSuccess = -1;
    }
    if (self.meeting == nil) {
        NSLog(@"请先创建白板会议");
        isSuccess = -2;
    }
    
    return isSuccess;
}

/**
 *  格式化请求参数
 *
 *  @param dict 参数字典集合
 *
 *  @return 请求参数数据
 */
- (NSData *)requestParamWithDict: (NSDictionary *)dict {
    NSData *data = [[NSData alloc] init];
    NSString *param = [self jsonStringWithDictionary:dict];
    NSData *loginInfo = [param dataUsingEncoding:NSUTF8StringEncoding];
    int len = [NSNumber numberWithLong:[param lengthOfBytesUsingEncoding:NSUTF8StringEncoding]].intValue;
    
    NSData *length = [NSData dataWithBytes: &len length: sizeof(len)];
    
    NSMutableData *data2 = [[NSMutableData alloc] init];
    [data2 appendData:length];
    [data2  appendData:loginInfo];
    
    data = data2;
    
    return data;
}
/**
 *  发送心跳包
 */
- (void)longConnectToSocket {
    // 根据服务器要求发送固定格式的数据，假设为指令@"longConnect"
    //    NSString *longConnect = @"{\"po\":\"active\"}";
    //
    //    NSData   *dataStream  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    //
    //    [self.socket writeData:dataStream withTimeout:1 tag:1];
    //NSLog(@"111");
    [self.socket readDataWithTimeout:-1 tag:1009];
}

// 切断socket
-(void)cutOffSocket{
    //标记 关闭类型
    self.socket.userData = [[NSNumber alloc] initWithInteger:SocketOfflineByUser];// 声明是由用户主动切断
    //关闭定时器
    //[self.connectTimer invalidate];
    //关闭连接
    [self.socket disconnect];
}
- (void)requireWhiteboardWithMeetingID:(NSString *)meetingID newBase64String:(NSString *)newBase64String toUserID:(NSString *)userID{
    
    
    //base64string
//    [self ]
    
    NSDictionary *userDict = @{
                                   @"meeting_id": meetingID,
                                   @"to_uid": userID,
                                   @"wb_data": newBase64String
                                   
                               };
    
    NSDictionary *paramDict = @{
                                    @"data": userDict,
                                    @"op": @"whiteboard",
                                    @"token": self.account.token
                                };
    
    NSData *paramData = [self requestParamWithDict:paramDict];
    
    [self.socket writeData:paramData withTimeout:-1 tag:1005];
    
    
}



/**
 *  处理接收到的数据
 *
 *  @param result 接收到的原始数据
 */
- (void)initResultData:(RequestResult *)result {
    
    /**
     *  收到的数据分成两类
        1.原始op: login、logout、actice、create、members
        2.白板操作op:invite、reject、whiteboard、join、exit、kickout、force_exit
    
     */
    if([result.op isEqualToString:NOTIFY_OP_NOTIFY]){
        
        if ([result.type isEqualToString:NOTIFY_OP_TYPE_WHITEBOARD]) {
            [self dealNotifyWithDict:result.data];
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_JOIN]){
            //
//            NSLog(@"收到会议邀请");
//            [self alert1];
            
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_KICKOUT]){
            
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_EXIT]){
            
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_FORCE_EXIT]){
            //收到退出消息
            
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_REJECT]){
            
        } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_INVITE]){
            NSLog(@"收到会议邀请");
            if (result.data != nil) {
                //
                InviteMeeting *inviteMeeting = [InviteMeeting mj_objectWithKeyValues:result.data];
                self.inviteMeeting = inviteMeeting;
//                [self alert1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self alert1];

                });
            }
            

        }
        
    }

    
    
    
    
    
    
    
    
    
    
    if ([result.result isEqualToString:@"ok"]) {
        
        if ([result.op isEqualToString:NOTIFY_OP_LOGIN]) {
            
            Account *account = [Account mj_objectWithKeyValues:result.data];
            self.account = account;
            NSLog(@"登录成功");
        } else if ([result.op isEqualToString:NOTIFY_OP_CREATE]) {
            NSLog(@"白板会议创建成功");
            Meeting *meeting = [Meeting mj_objectWithKeyValues:result.data];
            self.meeting = meeting;
            
        } else if ([result.op isEqualToString:NOTIFY_OP_LOGOUT]) {
            NSLog(@"白板会议登出成功");
        } else if ([result.op isEqualToString:NOTIFY_OP_MEMBERS]) {
            NSLog(@"白板会议成员查询成功");
            if (result.data != nil) {
                NSLog(@"会议成员:%@", result.data);
                if (result.data != nil) {
                    //self.members = result.data[];
                }
            } else {
                NSLog(@"当前会议成员为空");
            }
        } else if ([result.op isEqualToString:NOTIFY_OP_ACTIVE]) {
            NSLog(@"连接保活");
        } else if([result.op isEqualToString:NOTIFY_OP_NOTIFY]){
            
            if ([result.type isEqualToString:NOTIFY_OP_TYPE_WHITEBOARD]) {
                [self dealNotifyWithDict:result.data];
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_JOIN]){
                
                
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_KICKOUT]){
                
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_EXIT]){
                
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_FORCE_EXIT]){
                
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_REJECT]){
                
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_INVITE]){
                
            }
            
        }
        
        
        
    }
    
    
}

- (void)alert1 {
    
    
    NSString *string = [NSString stringWithFormat:@"收到白板会议邀请，来自:%@",self.inviteMeeting.uid];
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"会议通知" andMessage:string];
    
    __weak ConnectTool *weakSelf = self;
    [alertView addButtonWithTitle:@"接受"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alert) {
                              NSLog(@"Button1 Clicked%@",[NSThread currentThread]);
                              //加入会议
                              [weakSelf joinMeetingWithMID:weakSelf.inviteMeeting.meeting_id];
                          }];
    [alertView addButtonWithTitle:@"拒绝"
                             type:SIAlertViewButtonTypeDestructive
                          handler:^(SIAlertView *alert) {
                              NSLog(@"Button2 Clicked");
                              //拒绝会议
                              [weakSelf refuseMeetingWithReason:@"refuse" andMeetingID:weakSelf.inviteMeeting.meeting_id];
                          }];
    [alertView addButtonWithTitle:@"忽略"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alert) {
                              NSLog(@"Button3 Clicked");
                          }];
    
    alertView.willShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willShowHandler", alertView);
    };
    alertView.didShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didShowHandler", alertView);
    };
    alertView.willDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willDismissHandler", alertView);
    };
    alertView.didDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didDismissHandler", alertView);
    };
    
    alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
    
    [alertView show];
}

- (void)dealNotifyWithDict: (NSDictionary *)dict {
    
    NSString *base64Encoded = dict[@"wb_data"];
    
    
    if (base64Encoded == nil) {
        return;
    }
    
    NSData *nsdataFromBase64String = [[NSData alloc]
                                      initWithBase64EncodedString:base64Encoded options:0];
    
    struct  WhiteOperational  *infoStruct2;
    infoStruct2 = malloc((nsdataFromBase64String.length)*sizeof(char));
    
//    infoStruct2->Data = malloc((500 - 12)*sizeof(char));
    
    [nsdataFromBase64String getBytes:infoStruct2 length:nsdataFromBase64String.length];
    if (infoStruct2->CommandID > 0) {
        //
        NSLog(@"::::%d",infoStruct2->CommandID);
        
//        
//        Byte abyte[4];
//        
//        abyte[0] = (Byte) (0xff & infoStruct2->CommandID);
//        
//        abyte[1] = (Byte) ((0xff00 & infoStruct2->CommandID) >>8);
//        
//        abyte[2] = (Byte) ((0xff0000 & infoStruct2->CommandID) >>16);
//        
//        abyte[3] = (Byte) ((0xff000000 & infoStruct2->CommandID) >>24);
        
        
        if (infoStruct2->CommandID == 1) {
            //1.发送请求数据
            infoStruct2->CommandID = 2;
            //2.将结构体转化成base64String
            NSString *base64String = [self base64StringWithBytes:infoStruct2 length:12];
            
            // Print the Base64 encoded string
            NSLog(@"Encoded: %@", base64String);
            
            
            [self requireWhiteboardWithMeetingID:dict[@"meeting_id"] newBase64String:base64String toUserID:(NSString *) dict[@"from_uid"]];
        } else if(infoStruct2->CommandID == 3) {
            
            NSLog(@"接收到白板数据");
            [self initDrawModelWithData:nsdataFromBase64String];
        } else if(infoStruct2->CommandID == 4) {
            //删除一个对象
            
        } else if(infoStruct2->CommandID == 5) {
            //清屏
            //发送通知
            NSDictionary *dictData = @{@"msg":@"清屏", @"code":MSG_CLEAN};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
                
        } else if(infoStruct2->CommandID == 6) {
            //调整对象大小
            //初始化结构体
            struct SizeChange pan;
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            //移动对象
            Draw *draw = [[Draw alloc] init];
            draw.rect = CGRectMake(pan.rect.left, pan.rect.top, pan.rect.right - pan.rect.left, pan.rect.bottom - pan.rect.top);
            
            draw.ObjId = pan.ObjID;
            
            NSLog(@"id:%d, rect.left:%d, rect.right:%d, rect.top:%d, rect.bottom:%d", pan.ObjID, pan.rect.left, pan.rect.right, pan.rect.top, pan.rect.bottom);
            
            //1.包装成字典，把id、point
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"大小改变", @"code":MSG_SIZECHANGE};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
            
        } else if(infoStruct2->CommandID == 7) {
            //移动对象
            Draw *draw = [[Draw alloc] init];
            //初始化结构体
            struct MoveObj pan;
            
            int IdCount = (int)(nsdataFromBase64String.length - 20) / 4;
            NSLog(@"idCount%d", IdCount);
            
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            
            if (IdCount > 0) {
                //
                NSMutableArray *array = [NSMutableArray array];
            
                for (int i = 0; i < IdCount; i++) {
                    //
                    NSLog(@"id:%d", pan.ObjIDs[i]);
                    
                    int objID = pan.ObjIDs[i];
                    
                    [array addObject:[NSNumber numberWithInt:objID]];
                    
                }
                draw.ObjIds = array;
            }

            NSLog(@"id:%d, point.x:%d, point.y:%d", pan.ObjIDs[0], pan.point.x, pan.point.y);
            
            draw.point = CGPointMake(pan.point.x, pan.point.y);
    
            
//            draw.ObjId = pan.ObjID;
            //1.包装成字典，把id、point
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"改变位置", @"code":MSG_LOCCHANGE};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
            
            
        } else if(infoStruct2->CommandID == 8) {
            //改变颜色
            Draw *draw = [[Draw alloc] init];
            //初始化结构体
            struct ColorChange pan;
            
            int IdCount = (int)(nsdataFromBase64String.length - 12) / 4;
            NSLog(@"idCount%d", IdCount);
            
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            
            if (IdCount > 0) {
                //
                NSMutableArray *array = [NSMutableArray array];
                
                for (int i = 0; i < IdCount; i++) {
                    //
                    NSLog(@"id:%d", pan.ObjIDs[i]);
                    
                    int objID = pan.ObjIDs[i];
                    
                    [array addObject:[NSNumber numberWithInt:objID]];
                    
                }
                draw.ObjIds = array;
            }

            draw.color = [self colorWithDWORD:pan.dwColor andAlpha:1.0];
            
            draw.ObjId = pan.ObjID;
            
            //1.包装成字典，把id、point
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"改变位置", @"code":MSG_COLORCHANGE};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
        
        } else if(infoStruct2->CommandID == 9) {
            //改变字体
        } else if(infoStruct2->CommandID == 10) {
            //修改线宽
            //改变颜色
            Draw *draw = [[Draw alloc] init];
            //初始化结构体
            struct WidthChange pan;
            
            int IdCount = (int)(nsdataFromBase64String.length - 12) / 4;
            NSLog(@"idCount%d", IdCount);
            
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            
            if (IdCount > 0) {
                //
                NSMutableArray *array = [NSMutableArray array];
                
                for (int i = 0; i < IdCount; i++) {
                    //
                    NSLog(@"id:%d", pan.ObjIDs[i]);
                    
                    int objID = pan.ObjIDs[i];
                    
                    [array addObject:[NSNumber numberWithInt:objID]];
                    
                }
                draw.ObjIds = array;
            }
            
            draw.lineWidth = pan.nLineWidth;
            
            draw.ObjId = pan.ObjID;
            
            //1.包装成字典，把id、point
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"改变位置", @"code":MSG_WIDTHCHANGE};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });

        } else if(infoStruct2->CommandID == 11) {
            //修改文本内容
            Draw *draw = [[Draw alloc] init];
            //结构体容器
            struct TextChange pan;
            //结构体内-清空多余空间
            memset(&pan, 0, sizeof(struct TextChange));
            //用结构体去接收data数据
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            //有效的字节长度
            int len = nsdataFromBase64String.length - 4 * 3;
            Byte byte[len];
            memset(byte, 0, len);
            //将有效字节存入byte[]
            for (int i = 0; i < len; i++) {
                
                byte[i] = pan.pData[i];
                
            }
            //自定义编码方式GBK
            NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            
            //byte -> string
            NSString* str = [[NSString alloc]initWithBytes:byte length:len encoding:enc];
            
            NSLog(@"str = %@",str);
            
            if (str != nil) {
                //
                draw.ObjId = pan.ObjId;
                draw.text = str;
                
                //发送通知
                NSDictionary *dictData = @{@"data": draw, @"msg":@"文字", @"code":MSG_TEXTCHANGE};
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
                });
            }

        } else if(infoStruct2->CommandID == 12) {
            //手型指针操作
        } else if(infoStruct2->CommandID == 13) {
            //滚动条
        } else if(infoStruct2->CommandID == 14) {
            //白板页面操作
        } else if(infoStruct2->CommandID == 15) {
            //载入文件
        } else if(infoStruct2->CommandID == 16) {
            //设置背景图
        } else if(infoStruct2->CommandID == 17) {
            //设置背景色
        } else if(infoStruct2->CommandID == 18) {
            //所有对象列表
        } else if(infoStruct2->CommandID == 19) {
            //锁定
        } else if(infoStruct2->CommandID == 20) {
            //添加文档
        } else if(infoStruct2->CommandID == 21) {
            //文档查询
        } else if(infoStruct2->CommandID == 22) {
            //文档查询相应
        }
    }
    
    
    
}
/**
 *  根据DWORD转颜色对象
 *
 *  @param dwColor 4字节的dword数据
 *  @param alpha   透明度
 *
 *  @return UIColor
 */
- (UIColor *)colorWithDWORD:(int)dwColor andAlpha:(CGFloat)alpha{
    //这里在获取blue和red 需要根据顺序有差异
    int red = dwColor & 255;
    int green = dwColor >> 8 & 255;
    int blue = dwColor >> 16 & 255;
    
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

/**
 *  根据接收到的白板矢量数据，转化成模型数据 并处理
 *
 *  @param data 白板二进制数据
 */
- (void)initDrawModelWithData:(NSData *)data {
    //初始化结构体
    struct PanDraw pan;
    
    memset(&pan, 0, sizeof(struct PanDraw));
    
    [data getBytes:&pan length:data.length];
    
    int nColor = pan.dwColor;
    
    int red = nColor & 255;
    int green = nColor >> 8 & 255;
    int blue = nColor >> 16 & 255;
    
    
    Draw *draw = [[Draw alloc] init];
    
    
    if (pan.ObjType == 1 || pan.ObjType == 2) {
        
        draw.nCount = pan.nCount;
        
        draw.lineWidth = pan.nLineWidth;
        
        draw.ObjId = pan.ObjID;
        
        //设置画笔颜色
        draw.color = [self colorWithDWORD:pan.dwColor andAlpha:1.0];

        NSMutableArray *array = [NSMutableArray array];
        
        for (int i = 0; i < pan.nCount; i++) {
            struct POINT point = pan.points[i];
            SCPoint *objPoint = [[SCPoint alloc] init];
            objPoint.x = point.x;
            objPoint.y = point.y;
            
            [array addObject:objPoint];
        }
        draw.points = array;
        //发送通知
        NSDictionary *dictData = @{@"data": draw, @"msg":@"画笔", @"code":MSG_PAN};
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
        });
        
        
    } else if (pan.ObjType == 3) {
        //直线
        NSLog(@"直线");
    } else if (pan.ObjType == 4 || pan.ObjType == 5 || pan.ObjType == 6 || pan.ObjType == 7) {
        
        switch (pan.ObjType) {
            case 4:
                draw.type = DrawTypeRectangle;
                break;
            case 5:
                draw.type = DrawTypeRectangleFill;
                break;
            case 6:
                draw.type = DrawTypeEllipse;
                break;
            case 7:
                draw.type = DrawTypeEllipseFill;
                break;
                
            default:
                break;
        }
        //设置画笔颜色
        draw.color = [self colorWithDWORD:pan.dwColor andAlpha:1.0];
        //设置画笔宽度
        draw.lineWidth = pan.nLineWidth;
        
        draw.ObjId = pan.ObjID;
        //矩形、椭圆
        draw.rect =  CGRectMake(pan.rcRect.left, pan.rcRect.top, pan.rcRect.right - pan.rcRect.left, pan.rcRect.bottom - pan.rcRect.top);
        
        //draw.isFill = pan.ObjType % 2 != 0;
        
        //发送通知
        NSDictionary *dictData = @{@"data": draw, @"msg":@"图形", @"code":MSG_ICON};
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
        });
        
        
    } else if (pan.ObjType == 8) {
        //接收到2进制数据 data
        
        //结构体容器
        struct TextDraw pan;
        //结构体内-清空多余空间
        memset(&pan, 0, sizeof(struct TextDraw));
        //用结构体去接收data数据
        [data getBytes:&pan length:data.length];
        //有效的字节长度
        int len = pan.nCount;
        Byte byte[len];
        memset(byte, 0, len);
        //将有效字节存入byte[]
        for (int i = 0; i < pan.nCount; i++) {
            
            byte[i] = pan.pData[i];
        
        }
        //自定义编码方式GBK
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);

        //byte -> string
        NSString* str = [[NSString alloc]initWithBytes:byte length:pan.nCount encoding:enc];
        
        NSLog(@"str = %@",str);

        if (str != nil) {
            //
            draw.ObjId = pan.ObjID;
            draw.text = str;
            draw.rect =  CGRectMake(pan.rcRect.left, pan.rcRect.top, pan.rcRect.right, pan.rcRect.bottom);
            draw.color = [self colorWithDWORD:pan.dwColor andAlpha:1.0];
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"文字", @"code":MSG_TEXT};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });

            
        }
    } else if (pan.ObjType == 9) {
        //图片
        struct ImageDraw pan;
        [data getBytes:&pan length:data.length];
        Byte *byte = (Byte *)[data bytes];
        Byte *unByte = NULL;
        
        if((unByte = (Byte *)malloc(sizeof(Byte) * pan.dwUnSize)) == NULL)
        {
            printf("no enough memory!\n");
            return;
        }
        
        [self zipDecomPressWithPData:unByte PLen:pan.dwUnSize SData:byte SLen:pan.dwSize];
        
        NSLog(@"%d",pan.commondID);
        
        NSData *adata = [[NSData alloc] initWithBytes:unByte length:pan.dwUnSize];
        [adata writeToFile:@"/Users/sunluwei/Desktop/img.zip" atomically:YES];
        
//        NSData *unData = [self uncompressZippedData:adata];
        
        UIImage *image = [UIImage imageWithData:adata];
        
        if (image == nil) {
            //
            NSLog(@"图片处理失败");
        }
        
        //发送通知
//        NSDictionary *dictData = @{@"data": image, @"msg":@"图片", @"code":MSG_IMAGE};
//        
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
//        });
//        
        
        
    } else if (pan.ObjType == 10) {
        //文档图片
        
        
    }
    
    
    
    
}


/**图片解压*/
- (BOOL) zipDecomPressWithPData:(unsigned char*)pZipData PLen:(unsigned long) pZipLen SData: (const unsigned char *)sZipData SLen:(unsigned long) sZipLen
{
    int err = uncompress(pZipData, &pZipLen,(const Bytef*)sZipData, sZipLen);
    if (err != Z_OK)
    {
        NSLog(@"error:%d",err);
        return NO;
    }
    return YES;
}


- (NSString *)convertDataToHexStr:(NSData *)data {
    
    if (!data || [data length] == 0) {
        
        return @"";
        
    }
    
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange,BOOL *stop) {
        
        unsigned char *dataBytes = (unsigned char*)bytes;
        
        for (NSInteger i =0; i < byteRange.length; i++) {
            
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) &0xff];
            
            if ([hexStr length] == 2) {
                
                [string appendString:hexStr];
                
            } else {
                
                [string appendFormat:@"0%@", hexStr];
                
            }
            
        }
        
    }];
    
    
    
    return string;
    
}
- (NSString *)stringFromHexString:(NSString *)hexString {
    hexString = @"8c37";
    
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:NSUnicodeStringEncoding];
    //    printf("%s\n", myBuffer);
    free(myBuffer);
    
    NSString *temp1 = [unicodeString stringByReplacingOccurrencesOfString:@"\\u" withString:@"\\U"];
    NSString *temp2 = [temp1 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *temp3 = [[@"\"" stringByAppendingString:temp2] stringByAppendingString:@"\""];
    NSData *tempData = [temp3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString *temp4 = [NSPropertyListSerialization propertyListFromData:tempData
                                                       mutabilityOption:NSPropertyListImmutable
                                                                 format:NULL
                                                       errorDescription:NULL];
    NSString *string = [temp4 stringByReplacingOccurrencesOfString:@"\\r\\n" withString:@"\n"];
    
    NSLog(@"-------string----%@", string); //输出 谷歌
    return string;
}


/**
 *  讲bytes转化成base64 string
 *
 *  @param bytes  <#bytes description#>
 *  @param length <#length description#>
 *
 *  @return <#return value description#>
 */
- (NSString *)base64StringWithBytes:(nullable const void *)bytes length:(NSUInteger)length {
    
    NSData *data = [NSData dataWithBytes:bytes length:length];
    
    // Get NSString from NSData object in Base64
    NSString *base64Encoded = [data base64EncodedStringWithOptions:0];
    
    return base64Encoded;
    
}

/**
 *  加入会议
 *
 *  @param mID 会议ID
 */
- (void)joinMeetingWithMID:(NSString *)mID {
    
    NSString *op = NOTIFY_OP_TYPE_JOIN;
    
    NSDictionary *dict = @{
                               @"op":op,
                               @"token":self.account.token,
                               @"meeting_id":mID
                           };
    NSData *data = [self requestParamWithDict:dict];
    
    [self.socket writeData:data withTimeout:-1 tag:1002];

    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    //[self.connectTimer fire];
    
}

// dict字典转json字符串
- (NSString *)jsonStringWithDictionary:(NSDictionary *)dict
{
    if (dict && 0 != dict.count)
    {
        NSError *error = nil;
        // NSJSONWritingOptions 是"NSJSONWritingPrettyPrinted"的话有换位符\n；是"0"的话没有换位符\n。
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    
    return nil;
}
// json字符串转dict字典
- (NSDictionary *)jsonDictWithString:(NSString *)string
{
    if (string && 0 != string.length)
    {
        NSError *error;
        NSData *jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        
        if (error)
        {
            NSLog(@"json解析失败：%@", error);
            return nil;
        }
        
        return jsonDict;
    }
    
    return nil;
}

/**
 *  zlib解压
 *
 *  @param compressedData <#compressedData description#>
 *  @param deDataSize     <#deDataSize description#>
 *
 *  @return <#return value description#>
 */
- (NSData *)deCompressZlibData:(NSData *)compressedData withDeDataSize:(NSUInteger)deDataSize {
    if ([compressedData length] == 0) {
        return compressedData;
    } else {
        // 分配解压空间
        NSMutableData *decompressedData = [NSMutableData dataWithLength:deDataSize];
        
        // 设置解压参数
        z_stream stream;
        stream.next_in = (Bytef *)[compressedData bytes];
        stream.avail_in = (int)[compressedData length];
        stream.total_in = 0;
        stream.next_out = (Bytef *)[decompressedData mutableBytes];
        stream.avail_out = (int)[decompressedData length];
        stream.total_out = 0;
        stream.zalloc = 0;
        stream.zfree = 0;
        stream.opaque = 0;
        
        // 初始化
        if (inflateInit(&stream) == Z_OK) {
            // 解压缩
            int status = inflate(&stream, 2);
            
            if (status == 1) {
                // 清除
                if (inflateEnd(&stream) == 0) {
                    return decompressedData;
                }
            }
        }
    }
    
    return nil;
}
/***
 * zlib压缩函数
 * Level为压缩的程度,范围为0 - 9.
 * 0:不压缩; 1:速度最快,压缩程度最低; 9:速度最慢压缩程度最高; (-1):表示默认压缩程度,当前版本约等于6的压缩程度;
 * 若压缩失败,返回原数据.
 ***/
- (NSData *)compressZlibData:(NSData *)data compressLevel:(NSInteger)level {
    if (data == nil || [data length] == 0) {
        return data;
    }
    
    if (level < -1 || level > 9) {
        NSLog(@"压缩等级参数不正确");
        return data;
    }
    
    const unsigned long bufferedLength = 2 * [data length];
    
    NSMutableData *bufferedData = [NSMutableData dataWithLength:bufferedLength];
    
    z_stream stream;
    stream.next_in = (Bytef *)[data bytes];
    stream.avail_in = [data length];
    stream.total_in = 0;
    stream.next_out = (Bytef *)[bufferedData bytes];
    stream.avail_out = bufferedLength;
    stream.total_out = 0;
    stream.zalloc = 0;
    stream.zfree = 0;
    stream.opaque = 0;
    
    if (deflateInit(&stream, level) == 0) {
        
        int status = deflate(&stream, 2);
        
        if (status == 0) {
            status = deflate(&stream, 4);
        }
        
        if (status == 1) {
            
            if (deflateEnd(&stream) == 0) {
                
                uLong compressedLength = stream.total_out;
                NSData *compressedData = [[NSData alloc] initWithData:[bufferedData subdataWithRange:NSMakeRange(0, compressedLength)]];
                
                return compressedData;
            }
            
        }
    }
    return data;
}


-(NSData *)uncompressZippedData:(NSData *)compressedData
{
    
    if ([compressedData length] == 0) return compressedData;
    
    unsigned full_length = [compressedData length];
    
    unsigned half_length = [compressedData length] / 2;
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    z_stream strm;
    strm.next_in = (Bytef *)[compressedData bytes];
    strm.avail_in = [compressedData length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done) {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) {
            [decompressed increaseLengthBy: half_length];
        }
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) {
            done = YES;
        } else if (status != Z_OK) {
            break;
        }
        
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    // Set real length.
    if (done) {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    } else {
        return nil;
    }    
}


@end
