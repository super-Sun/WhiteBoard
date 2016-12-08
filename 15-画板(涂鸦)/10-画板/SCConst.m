//
//  SCConst.m
//  10-画板
//
//  Created by sunluwei on 16/11/17.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "SCConst.h"


/**清屏*/
NSString *const MSG_CLEAN = @"5";
/**画笔*/
NSString *const MSG_PAN = @"1";
/**图形*/
NSString *const MSG_ICON = @"2";
/**图片*/
NSString *const MSG_IMAGE = @"3";
/**文字*/
NSString *const MSG_TEXT = @"4";
/**位置改变*/
NSString *const MSG_LOCCHANGE = @"6";
/**大小改变*/
NSString *const MSG_SIZECHANGE = @"7";
/**颜色改变*/
NSString *const MSG_COLORCHANGE = @"8";
/**字体改变*/
NSString *const MSG_FONTCHANGE = @"9";
/**线宽改变*/
NSString *const MSG_WIDTHCHANGE = @"10";
/**文本改变*/
NSString *const MSG_TEXTCHANGE = @"11";
/**手型操作*/

/**滚动条操作*/
NSString *const MSG_SCROLLPAGE = @"12";
/**页面操作*/
NSString *const MSG_EDITPAGE = @"13";
/**文件再入*/
NSString *const MSG_LOADFILE = @"14";
/**设置背景图*/
NSString *const MSG_SET_BG_IMG = @"15";
/**设置背景颜色*/
NSString *const MSG_SET_BG_COLOR = @"16";



/** op:login */
NSString *const NOTIFY_OP_LOGIN = @"login";
/** op:logout */
NSString *const NOTIFY_OP_LOGOUT = @"logout";
/**op:active*/
NSString *const NOTIFY_OP_ACTIVE = @"actice";
/**创建白板会议*/
NSString *const NOTIFY_OP_CREATE = @"create";
/**查询白板会议成员*/
NSString *const NOTIFY_OP_MEMBERS = @"members";
/**白板操作*/
NSString *const NOTIFY_OP_NOTIFY = @"notify";
/**邀请白板会议*/
NSString *const NOTIFY_OP_TYPE_INVITE = @"invite";
/**拒绝白板会议*/
NSString *const NOTIFY_OP_TYPE_REJECT = @"reject";
/**白板绘制信息*/
NSString *const NOTIFY_OP_TYPE_WHITEBOARD = @"whiteboard";
/**加入会议*/
NSString *const NOTIFY_OP_TYPE_JOIN = @"join";
/**推出指定会议*/
NSString *const NOTIFY_OP_TYPE_EXIT = @"exit";
/**指定用户退出*/
NSString *const NOTIFY_OP_TYPE_KICKOUT = @"kickout";
/**强制退出*/
NSString *const NOTIFY_OP_TYPE_FORCE_EXIT = @"force_exit";