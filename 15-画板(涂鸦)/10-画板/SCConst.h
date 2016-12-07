//
//  SCConst.h
//  10-画板
//
//  Created by sunluwei on 16/11/17.
//  Copyright © 2016年 小码哥. All rights reserved.
//

#import <UIKit/UIKit.h>
UIKIT_EXTERN CGFloat const leng;

/**清屏*/
UIKIT_EXTERN NSString *const MSG_CLEAN;
/**画笔*/
UIKIT_EXTERN NSString *const MSG_PAN;
/**图形*/
UIKIT_EXTERN NSString *const MSG_ICON;
/**图片*/
UIKIT_EXTERN NSString *const MSG_IMAGE;
/**文字*/
UIKIT_EXTERN NSString *const MSG_TEXT;
/**位置改变*/
UIKIT_EXTERN NSString *const MSG_LOCCHANGE;
/**大小改变*/
UIKIT_EXTERN NSString *const MSG_SIZECHANGE;
/**颜色改变*/
UIKIT_EXTERN NSString *const MSG_ColorCHANGE;
/**字体改变*/
UIKIT_EXTERN NSString *const MSG_FontCHANGE;
/**线宽改变*/
UIKIT_EXTERN NSString *const MSG_WidthCHANGE;
/**文本改变*/
UIKIT_EXTERN NSString *const MSG_TextCHANGE;
/**手型操作*/

/**滚动条操作*/
UIKIT_EXTERN NSString *const MSG_ScrollPage;
/**页面操作*/
UIKIT_EXTERN NSString *const MSG_PageEdit;
/**文件再入*/
UIKIT_EXTERN NSString *const MSG_LoadFile;
/**设置背景图*/
UIKIT_EXTERN NSString *const MSG_SetBgImage;
/**设置背景颜色*/
UIKIT_EXTERN NSString *const MSG_SetBgColor;


/**op:login*/
UIKIT_EXTERN NSString *const NOTIFY_OP_LOGIN;
/**op:logout*/
UIKIT_EXTERN NSString *const NOTIFY_OP_LOGOUT;
/**op:active*/
UIKIT_EXTERN NSString *const NOTIFY_OP_ACTIVE;
/**创建白板会议*/
UIKIT_EXTERN NSString *const NOTIFY_OP_CREATE;
/**查询白板会议成员*/
UIKIT_EXTERN NSString *const NOTIFY_OP_MEMBERS;
/**白板操作*/
UIKIT_EXTERN NSString *const NOTIFY_OP_NOTIFY;
/**邀请白板会议*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_INVITE;
/**拒绝白板会议*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_REJECT;
/**白板绘制信息*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_WHITEBOARD;
/**加入会议*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_JOIN;
/**推出指定会议*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_EXIT;
/**强制退出*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_FORCE_EXIT;
/**指定用户退出*/
UIKIT_EXTERN NSString *const NOTIFY_OP_TYPE_KICKOUT;

typedef enum {
    /**点线*/
    DrawTypePoints = 0,
    /**直线*/
    DrawTypeLine,
    /**椭圆空心*/
    DrawTypeEllipse,
    /**矩形空心*/
    DrawTypeRectangle,
    /**图片*/
    DrawTypeImage,
    /**文字*/
    DrawTypeFont,
    /**空心和实心的分隔属性，无特殊意义*/
    DrawTypeFill,
    /**椭圆实心*/
    DrawTypeEllipseFill,
    /**矩形实心*/
    DrawTypeRectangleFill
   
}DrawType;

struct RECT {
    int left;
    int top;
    int right;
    int bottom;
};

struct POINT {
    int x;
    int y;
};

/**画笔结构体*/
struct PanDraw {
    int commondID;
    int pageID;
    int ObjId;
    /**对象类型*/
    int ObjType;
    /**数据大小*/
    int dwDataSize;
    /**对象ID*/
    int ObjID;
    /**颜色*/
    int dwColor;
    /**线宽*/
    int nLineWidth;
    /**对象位置*/
    struct RECT rcRect;
    /**点个数*/
    int nCount;
    /**点数据*/
    struct POINT points[1000];
    
};
/**直线、空心椭圆、实心椭圆、空心矩阵、实心矩阵*/
struct OtherDraw {
    int commondID;
    int pageID;
    int ObjId;
    /**对象类型*/
    int ObjType;
    /**数据大小*/
    int dwDataSize;
    /**对象ID*/
    int ObjID;
    /**颜色*/
    int dwColor;
    /**线宽*/
    int nLineWidth;
    /**对象位置*/
    struct RECT rcRect;
    
};
/**字体*/
struct LOGFONT {
    int lfHeight;
    int lfWidth;
    int lfEscapement;
    int lfOrientation;
    int lfWeight;
    Byte lfItalic;
    Byte lfUnderline;
    Byte lfStrikeOut;
    Byte lfCharSet;
    Byte lfOutPrecision;
    Byte lfClipPrecision;
    Byte lfQuality;
    Byte lfPitchAndFamily;
    char lfFaceName[32];   //wchar_t
};
/**文本*/
struct TextDraw {
    int commondID;
    int pageID;
    int ObjId;
    /**对象类型*/
    int ObjType;
    /**数据大小*/
    int dwDataSize;
    /**对象ID*/
    int ObjID;
    /**颜色*/
    int dwColor;
    /**对象位置*/
    struct RECT rcRect;
    /**字体*/
    struct LOGFONT font;
    char fo[32];
    /**字符长度*/
    int nCount;
    /**字符数据*/
    char pData[50];
};
/**图片结构体*/
struct ImageDraw {
    int commondID;
    int pageID;
    int ObjId;
    /**对象类型编码*/
    int ObjType;
    int dwDataSize;  //数据大小
    int ObjID;  //对象ID
    struct RECT rcRect;    //对象位置
    int dwUnSize;  //Bitmap位图数据未压缩大小
    int dwSize;    //Bitmap位图数据压缩后大小
    char pBuffer[500];       //使用压缩后的位图数据
};
/**对象移动*/
struct MoveObj {
    //头部
    int commondID;
    int pageID;
    int ObjId;
    /**点坐标*/
    struct POINT point;
    /**对象ID数组*/
    int ObjIDs[50];
    
};
/**对象大小改变*/
struct SizeChange {
    //头部
    int commondID;
    /**对象ID*/
    //忍不住吐槽一下，这个属性定义的顺序不严谨
    int ObjID;
    int pageID;
    /**调整后对象的区域Rect*/
    struct RECT rect;
    
};
struct ColorChange {
    //头部
    int commondID;
    /**对象ID*/
    //忍不住吐槽一下，服务端这个属性定义的顺序不严谨
    int ObjID;
    int pageID;
    /**颜色*/
    int dwColor;
    /**对象ID数组*/
    int ObjIDs[50];
};

