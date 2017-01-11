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
#import "GZIP.h"
#import "SCMember.h"



@interface ConnectTool() <GCDAsyncSocketDelegate>
/***/
@property(nonatomic ,strong) GCDAsyncSocket *socket;
/**计时器*/
@property (nonatomic, strong) NSTimer *connectTimer;

/**计时器*/
@property (nonatomic, strong) NSTimer *dealTimer;

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

@property (nonatomic, assign) int dataLenght;

@property (nonatomic, strong) NSMutableData *tempData;

@property (nonatomic, strong) NSMutableData *dataBuffer;

/***/
@property (nonatomic ,strong) UIAlertView *alert;

@property (nonatomic ,strong) NSOperationQueue *queue;

@end


@implementation ConnectTool

- (NSOperationQueue *)queue {
    
    if (!_queue) {
        self.queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
    
}

//- (Meeting *)meeting {
//    if (!_meeting) {
//        self.meeting = [[Meeting alloc] init];
//    }
//    return _meeting;
//}

- (NSMutableData *)dataBuffer {
    if (_dataBuffer == nil) {
        self.dataBuffer = [NSMutableData data];
    }
    return _dataBuffer;
}

- (NSMutableData *)tempData {
    if (_tempData == nil) {
        self.tempData = [NSMutableData data];
    }
    return _tempData;
}

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
    //创建一个socket对象
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    //连接
    NSError *error = nil;
    [self.socket connectToHost:self.host onPort:self.port withTimeout:5 error:&error];
    if (error) {
        //无法连接到主机
        NSLog(@"%@，无法连接主机",error);
        return NO;
    }
    //NSLog(@"%@",self.socket);
    return YES;
}
/**断开连接*/
- (void)disconnectToServer {
    [self cutOffSocket];
}
/**收到数据的回调*/
- (void)getDataFromServer {
    
}
/**发送白板数据*/
- (void)sendWhiteData:(NSData *)data {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *isLogin = [defaults objectForKey:@"wb_login"];
    NSString *isInMeeting = [defaults objectForKey:@"wb_inmeeting"];
    
    
    if ([isLogin isEqualToString:@"YES"] && [isInMeeting isEqualToString:@"YES"]) {
        
       // [self.socket readDataToLength:4 withTimeout:-1 tag:2016];
        
        NSString *base64Encoded = [data base64EncodedStringWithOptions:0];
        
        [self requireWhiteboardWithMeetingID:self.meeting.meeting_id newBase64String:base64Encoded toUserID:@-1];
        
    }

}

/**发送数据*/
- (void)sendDataToServer: (NSData *)data {
    

    [self.socket writeData: data withTimeout:5 tag:0];

    
    
}

#pragma mark -socket的代理
#pragma mark 连接成功

static dispatch_queue_t _dealQueue;

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%s",__func__);
    NSLog(@"%@",[NSThread currentThread]);
    
    NSDictionary *dictData = @{@"msg": @"connect_success"};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveLoginDataFromSever" object:nil userInfo:dictData];
    
    
    //连接成功后每隔XX秒发送心跳包
    // 每隔 x s像服务器发送心跳包
    
    //设置定时器
//    [self buildTimers];
    
}
/**
 *  设置定时器
 */
- (void)buildTimers {
    
    
    self.connectTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    
    self.dealTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(makeData) userInfo:nil repeats:YES];
    //[[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop mainRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop mainRunLoop] addTimer:self.dealTimer forMode:NSRunLoopCommonModes];

    
    
    
}


#pragma mark 断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    
    [self.connectTimer invalidate];
    
    if (err) {
        NSLog(@"连接失败");
        NSLog(@"%@",err);
        
        NSDictionary *dictData = @{@"msg": @"connect_error"};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveLoginDataFromSever" object:nil userInfo:dictData];
        
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
//        [self connectToServer];
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
    
//    [sock readDataWithTimeout:4 tag:tag];
    //    [sock readDataWithTimeout:-1 tag:1009];
    //[self.socket readDataToLength:4 withTimeout:-1 tag:tag];
    
    
}


- (void)buildData:(NSData *)data {
    
    @synchronized(self.tempData) {
        if (data.length ==4) {
            
            Byte *dataByte = (Byte *)[data bytes];
            int offset = 0;
            int dataLenght = (int) ((dataByte[offset] & 0xFF)
                                    | ((dataByte[offset+1] & 0xFF)<<8)
                                    | ((dataByte[offset+2] & 0xFF)<<16)
                                    | ((dataByte[offset+3] & 0xFF)<<24));
            
            self.dataLenght = dataLenght;
            
            return;
            
        }
        
        
        while(1) {
            
            if (data.length == self.dataLenght) {
                //执行后续正常操作
                [self.tempData appendData:data];
                
                data = [self.tempData copy];
                
                [self.tempData setLength:0];
                
                self.dataLenght = 0;
                
                [self dealOrignalData:data];
                
                break;
                
            } else if (data.length < self.dataLenght) {
                
                //1.把这次的data存起来
                [self.tempData appendData:data];
                
                //2.将self.dataLenght － data.length
                self.dataLenght = self.dataLenght - (int)data.length;
                
                //3.return
                break;
                
            } else if (data.length > self.dataLenght) {
                //1.把这次需要的数据取出来
                [self.tempData appendBytes:[data bytes] length:self.dataLenght];
                
                NSData *copyData = [data copy];
                
                data = [self.tempData mutableCopy];
                
                [self.tempData setLength:0];
                
                [self dealOrignalData:data];
                //2.判断后面的剩下部分是否大于4字节
                
                //2.1大于4字节
                if (copyData.length >= 4) {
                    //1.去4字节记录长度＝self.dataLenght
                    
                    //2.后面的字节大于0 就存入临时数组里面
                    NSData *lengthData = [copyData subdataWithRange:NSMakeRange(self.dataLenght, 4)];
                    
                    Byte *dataByte = (Byte *)[lengthData bytes];
                    int offset = 0;
                    int dataLenght2 = (int) ((dataByte[offset] & 0xFF)
                                             | ((dataByte[offset+1] & 0xFF)<<8)
                                             | ((dataByte[offset+2] & 0xFF)<<16)
                                             | ((dataByte[offset+3] & 0xFF)<<24));
                    //self.dataLenght = dataLenght2;
                    
                    
                    
                    NSData *restData = [copyData subdataWithRange:NSMakeRange(self.dataLenght + 4, copyData.length - self.dataLenght - 4)];
                    self.dataLenght = dataLenght2;
                    data = restData;
//                     [self.tempData setLength:0];
//                    
//                    [self.tempData appendData:restData];
//                    
//                    self.dataLenght = dataLenght2 - (int)restData.length;
                    //[self dealOrignalData:data];
                    
                }
                
                
                //2.1小于4字节
                
                
            }
        }
        
        
        
    }
    
    
}
/**
 *  4字节Data转int
 *
 *  @param lengthData NSData
 *
 *  @return Length
 */
- (int)getDataLengthWithData:(NSData *)lengthData {
    Byte *dataByte = (Byte *)[lengthData bytes];
    int offset = 0;
    int dataLenght = (int) ((dataByte[offset] & 0xFF)
                             | ((dataByte[offset+1] & 0xFF)<<8)
                             | ((dataByte[offset+2] & 0xFF)<<16)
                             | ((dataByte[offset+3] & 0xFF)<<24));
    
    return dataLenght;
}

-(void)parserData:(NSData *)data withTag:(long)tag {
    
    [self dealOrignalData:data];
    
    self.dataLenght = 0;
    
    [self.muData setLength:0];
    
    [self.socket readDataToLength:4 withTimeout:-1 tag:tag];
    
}

#pragma mark 读取数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"%@", [NSThread currentThread]);
    
//    [self.dataBuffer appendData:data];
    
    
    //1.判断data length > 4

//    [self buildData:[data copy]];
//    [self makeData:data];
//    
    
    
    
    NSLog(@"%s消息接收成功",__func__);
    
    //[self.tempData appendData:data];
    
//    NSInvocationOperation *operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(buildData:) object:data];
//    
//    [self.queue addOperation:operation];
    
    //SettingData* set = [SettingData shareSettingData];
//    
//    if (self.dataLenght == 0) {
//        
//        int dataLenght = [self getDataLengthWithData:data];
//        
//        self.dataLenght = dataLenght;
//        
//        if (dataLenght > 1448) {
//            //
//            self.dataLenght = dataLenght - 1448;
//            [sock readDataWithTimeout:-1 tag:tag];
//            
//            
//        } else {
//            
//            [sock readDataToLength:dataLenght withTimeout:-1 tag:tag];
//        }
//
//        return;
//    }
//
//    if (data.length < self.dataLenght) {
//        //
//        [self.muData appendData:data];
//        
//        if (self.dataLenght > 1448) {
//            self.dataLenght = self.dataLenght - 1448;
//            [sock readDataWithTimeout:-1 tag:tag];
//            
//        } else {
//            [sock readDataToLength:self.dataLenght withTimeout:-1 tag:tag];
//        }
//        
//    } else {
//        
//        [self.muData appendData:data];
//        
//        [self parserData:self.muData withTag:tag];
//    }

    
//    dispatch_async(_dealQueue, ^{
//        //
//        [self buildData:[data copy]];
//    });
    
    
    
    if (self.dataLenght == 0) {
        
        int dataLenght = [self getDataLengthWithData:data];
        
        self.dataLenght = dataLenght;
        
        NSLog(@"need length:%d", dataLenght);
            
        [sock readDataToLength:dataLenght withTimeout:-1 tag:tag];
        
//        [sock readDataToLength:dataLenght withTimeout:-1 buffer:self.muData bufferOffset:0 tag:tag];
        
        return;
        
    } else {
        NSLog(@"receiveLength:%d", data.length);

        [self.muData appendData:data];

        [self parserData:self.muData withTag:tag];
        
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    
    NSLog(@"partialLength:%ld", partialLength);
    
    NSLog(@"self.dataLenght:%d", self.dataLenght);
    if (partialLength < self.dataLenght) {
        
        //[sock readDataToLength:self.dataLenght - partialLength withTimeout:-1 tag:tag];
//        [sock readDataToLength:self.dataLenght - partialLength withTimeout:-1 tag:tag];
        
    }
    
    
}


- (void)dealOrignalData:(NSData *)data {
    
//    [self.dataBuffer resetBytesInRange:NSMakeRange(0, data.length + 4)];
    
    
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"data.length:%ld, resultStr:------%@",data.length, receiverStr);
    //NSLog(@"resultDict:%@",[self jsonDictWithString:receiverStr]);
    
    //NSLog(@"%s 收到的报文:%@",__func__,receiverStr);
    //获取到数据后发送通知
    
    //切换到主线程中发送
    
    if (receiverStr.length > 4) {
        
        RequestResult *result = [RequestResult mj_objectWithKeyValues:receiverStr];
        NSLog(@"result:%@", result);
        if (result != nil) {
            //处理收到的数据
            if ([result.op isEqualToString:NOTIFY_OP_MEMBERS]) {
                
                SCMember *member = [SCMember mj_objectWithKeyValues:receiverStr];
                if (member.data) {
                    //
                    NSArray *members = [Account mj_objectArrayWithKeyValuesArray:member.data];
                    /*---------------------
                     
                     //发送通知
                     //发送通知 data:会议信息和会议成员
                     
                     NSDictionary *dictData = @{@"data": meeting, @"msg":@"改变位置", @"code":MSG_REMOVE_OBJS};
                     
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
                     });
                     
                     */
                    
                    self.meeting.members = members;
                    
                    Meeting *meeting = [self.meeting copy];
                    //1.包装成字典，把id、point
                    //发送通知
                    NSDictionary *dictData = @{@"data": meeting, @"msg":@"会议信息", @"code":MSG_MEETING_DETAIL};
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
                    });
                    
                    
                }
                
                
            } else {
                NSLog(@"运行到这里");
                [self initResultData:result];
                
            }
            
            
            
            
        }
        
    }

    
    
}

#pragma mark -socket的代理End-

#pragma mark 用户操作
/**
 *  用户登录
 */
- (void)loginWithUserName:(NSString *)username password:(NSString *)password {
    //1.获取用户登入的信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *isLogin = [defaults objectForKey:@"wb_login"];
    
    
    if ([isLogin isEqualToString:@"YES"]) {
        return;
    }

    NSDictionary *dictParam = @{
                                    @"op":@"login",
                                    @"user":username,
                                    @"pwd":password
                                };
    
    //2.转化成协议格式
    NSData *parmData = [self requestParamWithDict:dictParam];
    
    
    [self.socket readDataToLength:4 withTimeout:-1 tag:2016];
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
    
    int isSuccess = 1;
    
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
    
    int len = (int)loginInfo.length;
    
    NSData *lenData = [NSData dataWithBytes: &len length: sizeof(len)];
    
    NSMutableData *data2 = [[NSMutableData alloc] init];
    [data2 appendData:lenData];
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
//    [self makeData:data];
//    NSLog(@"%@", [NSThread currentThread]);
    
    //[self.socket readDataWithTimeout:-1 tag:1009];
    
    [self.socket readDataWithTimeout:-1 tag:2017];
    
}
- (void)makeData {
    
//    if (data) {
//        [self.dataBuffer appendData:data];
//    }
    
    
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        //        NSLog(@"%@", [NSThread currentThread]);
//        
//        
//        
//        @synchronized(self.dataBuffer) {
//            
//            
//            if (self.dataBuffer.length < 4) {
//                return;
//            }
//            
//            //根据前面四个字节获取长度
//            int length = 0;
//            NSData *lengthData = [self.dataBuffer subdataWithRange:NSMakeRange(0, 4)];
//            Byte *dataByte = (Byte *)[lengthData bytes];
//            int offset = 0;
//            
//            length = (int) ((dataByte[offset] & 0xFF)
//                            | ((dataByte[offset+1] & 0xFF)<<8)
//                            | ((dataByte[offset+2] & 0xFF)<<16)
//                            | ((dataByte[offset+3] & 0xFF)<<24));
//            
//            
//            
//            
//            if (self.dataBuffer.length < length + 4) {
//                return;
//            }
//            
//            NSData *restData = [self.dataBuffer subdataWithRange:NSMakeRange(4, self.dataBuffer.length - 4)];
//            restData = [self.dataBuffer subdataWithRange:NSMakeRange(4, length)];
//            
//            self.dataBuffer = [NSMutableData dataWithData:[self.dataBuffer subdataWithRange:NSMakeRange(length + 4, self.dataBuffer.length - (length + 4))]];
//            
//            [self dealOrignalData:restData];
//            
//            if (self.dataBuffer.length > 4) {
//                //粘包处理
//                [self parseRestData];
//            }
//
//            
//            
//        }
//        
//        
//    });
//
//    
    
    
    
    
}
- (void)parseRestData {
    //获取长度
    int length = 0;
    NSData *lengthData = [self.dataBuffer subdataWithRange:NSMakeRange(0, 4)];
    Byte *dataByte = (Byte *)[lengthData bytes];
    int offset = 0;
    
    length = (int) ((dataByte[offset] & 0xFF)
                    | ((dataByte[offset+1] & 0xFF)<<8)
                    | ((dataByte[offset+2] & 0xFF)<<16)
                    | ((dataByte[offset+3] & 0xFF)<<24));
    
    if (self.dataBuffer.length < length + 4) {
        return;
    }
    
    NSData *restData = [self.dataBuffer subdataWithRange:NSMakeRange(4, self.dataBuffer.length - 4)];
    restData = [self.dataBuffer subdataWithRange:NSMakeRange(4, length)];
    
    self.dataBuffer = [NSMutableData dataWithData:[self.dataBuffer subdataWithRange:NSMakeRange(length + 4, self.dataBuffer.length - (length + 4))]];
    [self dealOrignalData:restData];
    
    
    
    if (self.dataBuffer.length > 4) {
        [self parseRestData];
    }
    
    
    
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

- (void)requireWhiteboardWithMeetingID:(NSString *)meetingID newBase64String:(NSString *)newBase64String toUserID:(NSNumber *)userID{
    
    
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
    
    //[self.socket readDataToLength:4 withTimeout:-1 tag:2016];
    
    [self.socket writeData:paramData withTimeout:-1 tag:1005];
    
}

-(void) performDismiss:(NSTimer *)timer
{
    [self.alert dismissWithClickedButtonIndex:0 animated:NO];
    
    [timer invalidate];
    
    timer = nil;
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
            //有新成员加入会员
            int uid = [result.data[@"uid"] intValue];
            
            if ([self.account.uid intValue] == uid) {
                //自己成功加入会议
                Meeting *meeting = [Meeting mj_objectWithKeyValues:result.data];
                self.meeting = meeting;
                
                NSDictionary *dict = @{
                                       @"code":@"join_success"
                                       };
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dict];
                
            }
            NSLog(@"加入会议join:%d", uid);
            
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

    
    
    
    
    
    if ([result.result isEqualToString:@"err"]) {
    
        if ([result.op isEqualToString:NOTIFY_OP_LOGIN]) {
            
            NSDictionary *dict = @{
                                   @"msg" : @"LOGIN_FAIL"
                                   };
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveLoginDataFromSever" object:nil userInfo:dict];
        
        }
    }
    
    
    
    
    if ([result.result isEqualToString:@"ok"]) {
        
        if ([result.op isEqualToString:NOTIFY_OP_LOGIN]) {
            
            Account *account = [Account mj_objectWithKeyValues:result.data];
            self.account = account;
            NSLog(@"登录成功");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //
                NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
                
                [userDefault removeObjectForKey:@"wb_login"];
                
                [userDefault setObject:@"YES" forKey:@"wb_login"];
                
                [userDefault synchronize];
                
                NSDictionary *dict = @{
                    @"msg" : @"LOGIN_SUCCESS"
                };
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveLoginDataFromSever" object:nil userInfo:dict];
            });
            
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
                
            } else {
                NSLog(@"当前会议成员为空");
            }
        } else if ([result.op isEqualToString:NOTIFY_OP_ACTIVE]) {
            NSLog(@"连接保活");
        } else if([result.op isEqualToString:NOTIFY_OP_NOTIFY]){
            
            if ([result.type isEqualToString:NOTIFY_OP_TYPE_WHITEBOARD]) {
                [self dealNotifyWithDict:result.data];
            } else if ([result.type isEqualToString:NOTIFY_OP_TYPE_JOIN]){
                NSLog(@"zhelijiaru");
#warning mark---
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
    
//    __weak ConnectTool *weakSelf = self;
    [alertView addButtonWithTitle:@"接受"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alert) {
                              NSLog(@"Button1 Clicked%@",[NSThread currentThread]);
                              //加入会议
                              dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                              
                              dispatch_async(queue, ^{
                                  //
                                  [self joinMeetingWithMID:self.inviteMeeting.meeting_id];
                              });
                          }];
    [alertView addButtonWithTitle:@"拒绝"
                             type:SIAlertViewButtonTypeDestructive
                          handler:^(SIAlertView *alert) {
                              NSLog(@"Button2 Clicked");
                              //拒绝会议
                              [self refuseMeetingWithReason:@"refuse" andMeetingID:self.inviteMeeting.meeting_id];
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
            
            
            [self requireWhiteboardWithMeetingID:dict[@"meeting_id"] newBase64String:base64String toUserID:(NSNumber *) dict[@"from_uid"]];
        } else if(infoStruct2->CommandID == 3) {
            
            NSLog(@"接收到白板数据");
            [self initDrawModelWithData:nsdataFromBase64String];
        } else if(infoStruct2->CommandID == 4) {
            //删除一个对象
            Draw *draw = [[Draw alloc] init];
            //初始化结构体
            struct RemovePaths pan;
            
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
                draw.ObjIds = [array copy];
            }
            
            //1.包装成字典，把id、point
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"改变位置", @"code":MSG_REMOVE_OBJS};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
            

            
            
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
            struct PageControl pan;
            //结构体内-清空多余空间
            memset(&pan, 0, sizeof(struct PageControl));
            //给结构体赋值
            [nsdataFromBase64String getBytes:&pan length:nsdataFromBase64String.length];
            
            Draw *draw = [[Draw alloc] init];
            draw.pageNum = pan.pageNum;
            draw.pageControlType = pan.type;
            
            /**发送通知
             * data:
             *     1:新增白板页
             *     2:切换白板页
             */
            NSDictionary *dictData = @{@"data": draw, @"msg":@"白板页操作", @"code":MSG_EDITPAGE};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });
            
            
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
 *  RGB值转DWORD
 *
 *  @param red   红色值
 *  @param green 绿色值
 *  @param blue  蓝色值
 *
 *  @return DWORD
 */
- (int)dwordFromRed:(int)red Green:(int)green Blue:(int)blue {
    // rgb(r,g,b)   =   一个整型值   =   r   +   g   *   256   + b*255*256
    
    return red + green * 256 + blue * 255 * 255;
    
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
//16777215
/**
 *  根据接收到的白板矢量数据，转化成模型数据 并处理
 *
 *  @param data 白板二进制数据
 */
- (void)initDrawModelWithData:(NSData *)data {
    //初始化结构体
    struct BasePan basePan;
    
    memset(&basePan, 0, sizeof(struct BasePan));
    
    [data getBytes:&basePan length:sizeof(struct BasePan)];
    
//    int nColor = pan.dwColor;
//    
//    int red = nColor & 255;
//    int green = nColor >> 8 & 255;
//    int blue = nColor >> 16 & 255;
    
    
    Draw *draw = [[Draw alloc] init];
    
    
    if (basePan.ObjType == 1 || basePan.ObjType == 2) {
        
        //初始化结构体
        struct PanDraw pan;
        
        memset(&pan, 0, sizeof(struct PanDraw));
        
        [data getBytes:&pan length:data.length];
        
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
        
        
    } else if (basePan.ObjType == 3) {
        //直线
        NSLog(@"直线");
    } else if (basePan.ObjType == 4 || basePan.ObjType == 5 || basePan.ObjType == 6 || basePan.ObjType == 7) {
        
        switch (basePan.ObjType) {
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
        //初始化结构体
        struct PanDraw pan;
        
        memset(&pan, 0, sizeof(struct PanDraw));
        
        [data getBytes:&pan length:data.length];
        
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
        
        
    } else if (basePan.ObjType == 8) {
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
            draw.rect =  CGRectMake(pan.rcRect.left, pan.rcRect.top, pan.rcRect.right - pan.rcRect.left, pan.rcRect.bottom - pan.rcRect.top);
            draw.color = [self colorWithDWORD:pan.dwColor andAlpha:1.0];
            //发送通知
            NSDictionary *dictData = @{@"data": draw, @"msg":@"文字", @"code":MSG_TEXT};
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
            });

            
        }
    } else if (basePan.ObjType == 9) {
        //图片
        struct ImageDraw pan;
        
        memset(&pan, 0, sizeof(struct ImageDraw));
        
        [data getBytes:&pan length:48];
        //Byte *byte = (Byte *)[data bytes];
        int orSize = pan.dwSize;
        Byte unByte[orSize];
        
        memset(unByte, 0, orSize);
        
//        for (int i = 0; i < orSize; i++) {
//            //
//            unByte[i] = pan.pBuffer[i];
//        }
        
        
//        NSData *data2 = [NSData dataWithBytes:unByte length:pan.dwSize];
        
        NSData *data2 = [data subdataWithRange:NSMakeRange(48, pan.dwSize)];
        
//        NSData *adata = [self deCompressZlibData:data2 withDeDataSize:pan.dwUnSize];
        NSData *adata = [data2 customerGunzippedData];
        
        NSLog(@"%d",pan.commondID);
        
//        NSData *data = [adata gunzippedData];
        
        UIImage *image = [UIImage imageWithData:adata];
//        
//        [adata writeToFile:@"/Users/sunluwei/Desktop/img.zip" atomically:YES];
        
//        NSData *unData = [self uncompressZippedData:adata];
        
//        UIImage *image = [UIImage imageWithData:adata];
        
        if (image == nil) {
            //
            NSLog(@"图片处理失败");
            return;
        }
        draw.ObjId = pan.ObjID;
        draw.image = image;
        draw.rect = CGRectMake(pan.rcRect.left, pan.rcRect.top, pan.rcRect.right - pan.rcRect.left, pan.rcRect.bottom - pan.rcRect.top);
        //发送通知
        NSDictionary *dictData = @{@"data": draw, @"msg":@"图片", @"code":MSG_IMAGE};
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataFromSever" object:nil userInfo:dictData];
        });
//
        
        
    } else if (basePan.ObjType == 10) {
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
 *  清除页面内容
 *
 *  @param PageNum 页面编号
 */
- (void)cleanPageWithPageNum:(int)PageNum {
    
    struct PageClean pan;
    
    memset(&pan, 0, sizeof(struct PageClean));
    
    pan.commondID = 5;
    
    pan.ObjId = 0;
    
    pan.pageID = PageNum;

    NSData *data = [NSData dataWithBytes:&pan length:sizeof(struct PageClean)];
    
    [self sendWhiteData:data];
}

/**
 *  发送创建白板页指令
 *
 *  @param pageNum 白板页码
 *  @param type    类型
 */
- (void)pageControlWithPageNum:(char)pageNum andControlType:(char)type {
    
    struct PageControl pan;
    
    memset(&pan, 0, sizeof(struct PageControl));
    
    pan.commondID = 14;
    
    pan.ObjId = 0;
    
    pan.pageID = 0;
    
    pan.type = type;
    
    pan.pageNum = pageNum;
    
    NSData *data = [NSData dataWithBytes:&pan length:sizeof(struct PageControl)];
    
    [self sendWhiteData:data];
    
}

/**
 *  加入会议
 *
 *  @param mID 会议ID
 */
- (void)joinMeetingWithMID:(NSString *)mID {
    
    self.meeting.meeting_id = mID;
    
    NSString *op = NOTIFY_OP_TYPE_JOIN;
    
    NSDictionary *dict = @{
                               @"op":op,
                               @"token":self.account.token,
                               @"meeting_id":mID
                           };
    NSData *data = [self requestParamWithDict:dict];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault removeObjectForKey:@"wb_inmeeting"];
    [userDefault setObject:@"YES" forKey:@"wb_inmeeting"];
    [userDefault synchronize];
    
    [self.socket writeData:data withTimeout:-1 tag:1002];
#warning 这里注释掉了
//    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
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
        
        
        int result = inflateInit2(&stream, -MAX_WBITS);
        
        // 初始化
        if (result == Z_OK) {
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
        
        int status = inflate(&stream, 2);
        
        if (status == 0) {
            status = inflate(&stream, 4);
        }
        
        if (status == 1) {
            
            if (inflateEnd(&stream) == 0) {
                
                uLong compressedLength = stream.total_out;
                NSData *compressedData = [[NSData alloc] initWithData:[bufferedData subdataWithRange:NSMakeRange(0, compressedLength)]];
                
                return compressedData;
            }
            
        }
    }
    return data;
}

#pragma mark-UIAlertViewDelegate
- (void)willPresentAlertView:(UIAlertView *)myAlertView {
    myAlertView.frame = CGRectMake( 100, 100, 320, 50 );
    
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
