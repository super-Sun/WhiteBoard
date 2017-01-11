//
//  DrawView.m
//  10-画板
//
//  Created by sunluwei on 16/11/16.
//  Copyright © 2016年 scooper. All rights reserved.
//

#import "DrawView.h"
#import "MyBezierPath.h"
#import "SCConst.h"
#import "SCPoint.h"
#import "SCPicture.h"


@interface DrawView()

/** 当前绘制的路径 */
@property (nonatomic, strong) MyBezierPath *path;

//保存当前绘制的所有路径
@property (nonatomic, strong) NSMutableArray *allPathArray;

//保存所有白板页路径
@property (nonatomic, strong) NSMutableArray *allPagePathArray;

//当前路径的线宽
@property (nonatomic, assign) CGFloat width;

//当前路径的颜色
@property (nonatomic, strong) UIColor *color;
//手势
@property (nonatomic, strong) UIPanGestureRecognizer *recognizer;
//点集合
@property (nonatomic, strong) NSMutableArray *points;

@end

@implementation DrawView




- (instancetype)initWithFrame:(CGRect)frame {
    
    if ([super initWithFrame:frame]) {
        //添加手势
        [self addRecognizer];
        
        self.width = 1;
        self.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
    }
    
    return self;
    
    
}

/**
 *  lazy
 *
 *  @return <#return value description#>
 */

- (NSMutableArray *)points {
    if (!_points) {
        
        self.points = [NSMutableArray array];
    }
    return _points;
}


- (NSMutableArray *)allPathArray {
    
    if (_allPathArray == nil) {
        _allPathArray = [NSMutableArray array];
    }
    return _allPathArray;
}

- (NSMutableArray *)allPagePathArray {
    if (_allPagePathArray == nil) {
        self.allPagePathArray = [NSMutableArray array];
        
        [self.allPagePathArray addObject:self.allPathArray];
    }
    return _allPagePathArray;
}


- (void)awakeFromNib {
    //添加手势
    [self addRecognizer];
    
    self.width = 1;
    self.color = [UIColor colorWithRed:0 green:0 blue:0 alpha:1];
}
/**删除手势*/
- (void)removeRecognizer {
    
    if (self.recognizer != nil) {
        
        [self removeGestureRecognizer:self.recognizer];
        
        self.recognizer = nil;
    }
    
    return;
    
}
/**添加手势*/
- (void)addRecognizer {
    
    if (self.recognizer == nil) {
        //添加手势
        UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        
        self.recognizer = recognizer;
        
        [self addGestureRecognizer:recognizer];
        
    }
    
    return;

}
/**
 *  获取白板页数
 *
 *  @return 白板页数
 */
- (int)getPageNum {
    
    return (int)self.allPagePathArray.count;
    
}
/**
 *  获取当前页码
 *
 *  @return 当前页码
 */
- (int)getCurrentPageNum {
    
    return (int)[self.allPagePathArray indexOfObject:self.allPathArray];
}


/**
 *  添加图片
 *
 *  @param image 图片
 */
-(void)setImage:(UIImage *)image {
   
    _image = image;
    
    //添加图片添加到数组当中
    
    [self.allPathArray addObject:image];
    
    //重绘
    [self setNeedsDisplay];
    
    
    
//    CGSize size= CGSizeMake (image.size.width , image.size.height); // 画布大小
//    
//    UIGraphicsBeginImageContextWithOptions (size, NO, 0);
// 
//    [image drawAtPoint : CGPointMake ( 0 , 0 )];
//    
//    // 获得一个位图图形上下文
//    
//    CGContextRef context= UIGraphicsGetCurrentContext ();
//    
//    CGContextDrawPath (context, kCGPathStroke );
//    
//    [image drawInRect:CGRectMake(0,0,size.width,size.height)];
//    // 返回绘制的新图形
//    
//    UIImage *newImage= UIGraphicsGetImageFromCurrentImageContext ();
//    
//    UIGraphicsEndImageContext ();
    

}

- (void)drawWithFontText:(NSString *)text andRect:(CGRect)rect andPathID:(int)pathID{
    
    //1.把当前的View做一个截屏
    CGSize size =[text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
    rect.size = size;
    //画布大小
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    //2.获得一个位图图形上下文
    CGContextRef context=UIGraphicsGetCurrentContext();
    
    CGContextDrawPath(context, kCGPathStroke);

    //3.想要添加的文字
    [text drawAtPoint:CGPointMake(0, 0) withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:16],NSForegroundColorAttributeName:self.color}];
    
    
    UIImage *image = (UIImage *)UIGraphicsGetImageFromCurrentImageContext();
    
    //关闭上下文.
    UIGraphicsEndImageContext();
    
    SCPicture *picture = [[SCPicture alloc] init];
    picture.image = image;
    picture.pathID = pathID;
    picture.rect = rect;
    picture.text = text;
    picture.color = self.color;
//1067340658
    [self.allPathArray addObject:picture];
    
    [self setNeedsDisplay];
    
}

//清屏
- (void)clear {
    //清空所有的路径
    [self.allPathArray removeAllObjects];
    //重绘
    [self setNeedsDisplay];
    
}
//撤销
- (void)undo {
    //删除最后一个路径
    [self.allPathArray removeLastObject];
    //重绘
    [self setNeedsDisplay];
}
//橡皮擦
- (void)erase {
    [self setLineColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1]];
    //[self addText];
}

//设置线的宽度
- (void)setLineWidth:(CGFloat)lineWidth {
    self.width = lineWidth;
 
}

//设置线的颜色
- (void)setLineColor:(UIColor *)color {
    
    if (color == nil) {
        NSLog(@"nilnilnilnilo");
        return;
    }
    self.color = color;
    
    //[self moveLine];
    
}
/**
 *  图形位置改变
 *
 *  @param point  <#point description#>
 *  @param pathID <#pathID description#>
 */
- (void)iconLocalChangeWithPoint:(CGPoint)point andPathIDs:(NSArray *)pathIDs {
    
    if (pathIDs.count <= 0) {
        return;
    }
//    NSSet *set = [NSSet setWithArray:self.allPathArray];
//    self.allPathArray = [NSMutableArray arrayWithArray:[set allObjects]];
    
    //
    for (int i = 0; i < pathIDs.count; i++) {
        //
        NSNumber *ID = pathIDs[i];
        NSLog(@"ids not nil, num:%lu", pathIDs.count);
        int pathID = [ID intValue];
        //为了提高性能 选择等所有路径计算完成之后再重绘
        for (int i = 0; i < self.allPathArray.count; i++) {
            
             NSLog(@"allPathArray not nil, num:%lu", self.allPathArray.count);
            if ([self.allPathArray[i] isKindOfClass:[SCPicture class]]) {
                //图片或者文字
                //NSLog(@"font");
                SCPicture *picture = (SCPicture *)self.allPathArray[i];
                if (picture.pathID == pathID) {
                    //1.移除原来的对象
                    //[self.allPathArray removeObjectAtIndex:i];
                    
                    //2.
                    CGRect newRect = picture.rect;
                    newRect = CGRectMake(picture.rect.origin.x + point.x, picture.rect.origin.y + point.y, picture.rect.size.width, picture.rect.size.height);
                    
                    
                    
                    if (picture.text == nil) {
                        //纯图片
                        picture.rect = newRect;
                        
                       // [self.allPathArray addObject:picture];
                        [self.allPathArray replaceObjectAtIndex:i withObject:picture];
                        
                       
                    } else {
                        //文字图片
                        
                        self.color = picture.color;
                        
                        [self.allPathArray removeObjectAtIndex:i];
                        
                        [self drawWithFontText:picture.text andRect:newRect andPathID:pathID];

                    }
                    
                    
                    break;
                }
            
            }else if ([self.allPathArray[i] isKindOfClass:[MyBezierPath class]]) {
                //路径
                MyBezierPath *path = self.allPathArray[i];
                
                if (path.pathID == pathID) {
                    //找到对象
                    //找到的对象分成继红类型：点线、矩形、椭圆、直线、文字、图片。。。
                    if (path.type == DrawTypeRectangle
                        || path.type == DrawTypeEllipse
                        || path.type == DrawTypeEllipseFill
                        || path.type == DrawTypeRectangleFill) {
                        //矩阵
                        CGRect rect = path.rect;
                        rect.origin.x = path.rect.origin.x + point.x;
                        rect.origin.y = path.rect.origin.y + point.y;
                        MyBezierPath *newPath = [MyBezierPath bezierPathWithRect:rect andType:path.type];
                        
                        [newPath setProperyeWithPath:path andNewRect:rect];
                        
//                        [self.allPathArray removeObjectAtIndex:i];
//                        
//                        [self.allPathArray addObject:newPath];
                        [self.allPathArray replaceObjectAtIndex:i withObject:newPath];
                  
                    } else if (path.type == DrawTypePoints) {
                        NSArray *points = path.points;
                        NSMutableArray *newPoints = [NSMutableArray array];
                        for (int i = 0; i < points.count; i++) {
                            //
                            SCPoint *scPoint = points[i];
                            scPoint.x = scPoint.x + point.x;
                            scPoint.y = scPoint.y + point.y;
                            
                            [newPoints addObject:scPoint];
                        }
                        path.points = newPoints;
                        
                        //
                        MyBezierPath *newPath = [[MyBezierPath alloc] init];
                        //self.path = newPath;
                        newPath.color = path.color;
                        newPath.pathID = pathID;
                        newPath.points = newPoints;
                        newPath.lineWidth = path.lineWidth;
                        SCPoint *point = points[0];
                        [newPath moveToPoint:CGPointMake(point.x , point.y)];
                        
                        
                        
                        for (int i = 1; i < points.count; i++) {
                            
                            SCPoint *point = points[i];
                            
                            [newPath addLineToPoint:CGPointMake(point.x, point.y)];
                        }
                        
//                        [self.allPathArray removeObjectAtIndex:i];
//                        
//                        [self.allPathArray addObject:newPath];
                        [self.allPathArray replaceObjectAtIndex:i withObject:newPath];
                        
                    }
                
                    //结束本次循环
                    break;
                
                }
            }
            
        }

        
    }
    
    //redraw the view
    [self setNeedsDisplay];
}
/**
 *  批量修改颜色
 *
 *  @param color   要修改的颜色
 *  @param pathIDs pathIDs
 */
- (void)iconColorChangeWithColor:(UIColor *)color andPathIDs:(NSArray *)pathIDs {
    
    if (pathIDs.count <= 0) {
        return;
    }
    
    //
    for (int i = 0; i < pathIDs.count; i++) {
        //
        NSNumber *ID = pathIDs[i];
        NSLog(@"ids not nil, num:%lu", pathIDs.count);
        int pathID = [ID intValue];
        //为了提高性能 选择等所有路径计算完成之后再重绘
        for (int i = 0; i < self.allPathArray.count; i++) {
            
            NSLog(@"allPathArray not nil, num:%lu", self.allPathArray.count);
            if ([self.allPathArray[i] isKindOfClass:[SCPicture class]]) {
                //文字
                //NSLog(@"font");
                SCPicture *picture = (SCPicture *)self.allPathArray[i];
                
                if (picture.pathID == pathID) {
                    
                    //纯图片
                    if (picture.text == nil) {
                        break;
                    }
                    
                    //移除原来的对象
                    [self.allPathArray removeObjectAtIndex:i];
                    picture.color = color;
                    self.color = color;
                    //添加新的
                    [self drawWithFontText:picture.text andRect:picture.rect andPathID:pathID];
                    break;
                }
                
            }else if ([self.allPathArray[i] isKindOfClass:[MyBezierPath class]]) {
                //路径
                MyBezierPath *path = self.allPathArray[i];
                
                if (path.pathID == pathID) {
                    //找到对象
                    //找到的对象分成继红类型：点线、矩形、椭圆、直线、文字、图片。。。
                    
                    path.color = color;
                    
                    
                    [self.allPathArray replaceObjectAtIndex:i withObject:path];
                    
                    //结束本次循环
                    break;
                    
                }
            }
            
        }
        
        
    }
    
    //redraw the view
    [self setNeedsDisplay];

    
    
}

/**
 *  批量修改线宽
 *
 *  @param lineWidth 线宽
 *  @param pathIDs   ID数组
 */
- (void)iconWidthChangeWithWidth:(int)lineWidth andPathIDs:(NSArray *)pathIDs {
    
    if (pathIDs.count <= 0) {
        return;
    }
    
    //
    for (int i = 0; i < pathIDs.count; i++) {
        //
        NSNumber *ID = pathIDs[i];
        NSLog(@"ids not nil, num:%lu", pathIDs.count);
        int pathID = [ID intValue];
        //为了提高性能 选择等所有路径计算完成之后再重绘
        for (int i = 0; i < self.allPathArray.count; i++) {
            
            NSLog(@"allPathArray not nil, num:%lu", self.allPathArray.count);
            if ([self.allPathArray[i] isKindOfClass:[SCPicture class]]) {
                //目前windows客户端没有相应操作，这里接口预留
                break;
            }else if ([self.allPathArray[i] isKindOfClass:[MyBezierPath class]]) {
                //路径
                MyBezierPath *path = self.allPathArray[i];
                
                if (path.pathID == pathID) {
                    //找到对象
                    //找到的对象分成继红类型：点线、矩形、椭圆、直线、文字、图片。。。
                    
                    path.lineWidth = lineWidth;
                    
                    [self.allPathArray replaceObjectAtIndex:i withObject:path];
                    
                    //结束本次循环
                    break;
                    
                }
            }
            
        }
        
        
    }
    
    //redraw the view
    [self setNeedsDisplay];
    
    
    
}


/**
 *  图形大小改变
 *
 *  @param rect   新的rect
 *  @param pathID 要改变的pathID
 */
- (void)iconSizeChangeWithRect:(CGRect)rect andPathID:(int)pathID {
    
    for (int i = 0; i < self.allPathArray.count; i++) {
        //
        if ([self.allPathArray[i] isKindOfClass:[MyBezierPath  class]]) {
            
            MyBezierPath *path = self.allPathArray[i];
            
            if (path.pathID == pathID) {
                
                MyBezierPath *newPath = [MyBezierPath bezierPathWithRect:rect andType:path.type];
                //获取path原来的基本属性，同时更新rect
                [newPath setProperyeWithPath:path andNewRect:rect];
                
                [self.allPathArray replaceObjectAtIndex:i withObject:newPath];
                
                [self setNeedsDisplay];
                
                break;
            }
           
        }else if ([self.allPathArray[i] isKindOfClass:[SCPicture  class]]) {
            
            SCPicture *picture = self.allPathArray[i];
            
            picture.rect = rect;
            
            picture.image = [self resizeImage:picture.image toSize:rect.size];
            
            [self.allPathArray replaceObjectAtIndex:i withObject:picture];
            
            [self setNeedsDisplay];
            
            break;
            
        }
    }
    
}
/**
 *  文字改变
 *
 *  @param text   修改后的文字
 *  @param pathID 元素ID
 */
- (void)fontContentChangeWithText:(NSString *)text andPathID:(int)pathID {
    
    for (int i = 0; i < self.allPathArray.count; i++) {
        //
        if ([self.allPathArray[i] isKindOfClass:[SCPicture class]]) {
            //
            SCPicture *picture = self.allPathArray[i];
            
            if (picture.pathID == pathID) {
                //移除原来的path
                [self.allPathArray removeObjectAtIndex:i];
                
                self.color = picture.color;
                
                [self drawWithFontText:text andRect:picture.rect andPathID:pathID];
                
                break;
            }
        }
    }
}
/**
 *  根据Size改变图片大小
 *
 *  @param image  图片
 *  @param reSize 需要改变的大小
 *
 *  @return 指定大小的图片
 */
- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)reSize

{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return reSizeImage;
    
}


/**添加图片*/
- (void)drawImageWithImage:(UIImage *)image andPathID:(int)pathID rect:(CGRect)rect {
    
    SCPicture *picture = [[SCPicture alloc] init];
    
    picture.image = image;
    
    picture.rect = CGRectMake(rect.origin.x, rect.origin.y, image.size.width, image.size.height);
    
    picture.pathID = pathID;
    
    //添加图片添加到数组当中
    
    [self.allPathArray addObject:picture];
    
    //重绘
    [self setNeedsDisplay];

    
}

/**删除paths*/
- (void)removePathsWithPathIDs:(NSArray *)pathIDs {
    
    for (int i = 0; i < pathIDs.count; i++) {
        
        int pathID = [pathIDs[i] intValue];
        
        for (MyBezierPath *path in self.allPathArray) {
            //
            if (path.pathID == pathID) {
                
                [self.allPathArray removeObject:path];
                
                break;
            }
        }
    }
    
    [self setNeedsDisplay];
    
    
}
/**
 *  私有方法：图片位置调整
 *
 *  @param rect    rect
 *  @param picture picture
 */
- (void)iconImageLocalChangeWithRect:(CGRect)rect andPicture:(SCPicture *)picture {
    
    picture.rect = rect;
    
    [self.allPathArray addObject:picture];
    
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
    // rgb(r,g,b)   =   一个整型值   =   r   +   g   *   256   + b*256*256
    
    return red + green * 256 + blue * 256 * 256;
 
    
}



- (void)pan:(UIPanGestureRecognizer *)pan {
    
    //获取的当前手指的点
    CGPoint curP = [pan locationInView:self];
    //判断手势的状态
    if(pan.state == UIGestureRecognizerStateBegan) {
        
        [self.points removeAllObjects];
        self.path = nil;
        
        [self.points addObject:[SCPoint point:curP]];

        //创建路径
        //UIBezierPath *path = [UIBezierPath bezierPath];
        MyBezierPath *path = [[MyBezierPath alloc] init];
        
        self.path = path;
        
        //设置起点
        [path moveToPoint:curP];
        
        //设置线的宽度
        [path setLineWidth:self.width];
        //设置线的颜色
        path.color = self.color;
        path.pathID = [self initPathID];
        NSLog(@"begin:---------");
        [self.allPathArray addObject:path];
        
    } else if(pan.state == UIGestureRecognizerStateChanged) {
        NSLog(@"change::---------");
        [self.points addObject:[SCPoint point:curP]];
        
        //绘制一根线到当前手指所在的点
        [self.path addLineToPoint:curP];
        //重绘
        [self setNeedsDisplay];
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        NSLog(@"end::---------");
        [self.points addObject:[SCPoint point:curP]];
        
        
        
        self.path.points = [self.points copy];
        
        //[self.allPathArray addObject:self.path];
        
        //触发代理方法
        if([self.delegate respondsToSelector:@selector(panDrawView:andData:)]) {
            
            struct PanDraw pan;
            //结构体内-清空多余空间
            memset(&pan, 0, sizeof(struct PanDraw));
        
            pan.commondID = 3;
            pan.pageID = self.path.pathID;
            pan.ObjId = (int)[self.allPagePathArray indexOfObject:self.allPathArray];
            pan.ObjType = 1;
            
            /**对象ID*/
            pan.ObjID = self.path.pathID;
            /**颜色*/
            const CGFloat *components = CGColorGetComponents(self.color.CGColor);
            
            pan.dwColor = [self dwordFromRed:components[0] * 255.0 Green:components[1] * 255.0 Blue:components[2] * 255.0];
            /**线宽*/
            pan.nLineWidth = self.width;
            
            /**点个数*/
            pan.nCount = (int)self.points.count;
            
            SCPoint *scpoint = [self.points firstObject];
            int left = scpoint.x;
            int right = scpoint.x;
            int top = scpoint.y;
            int bottom = scpoint.y;
            
            for (int i = 0; i < pan.nCount; i++) {
                SCPoint *point = self.points[i];
                pan.points[i].x = point.x;
                pan.points[i].y = point.y;
                
                left = point.x < left ? point.x : left;
                right = point.x > right ? point.x : right;
                top = point.y < top ? point.y : top;
                bottom = point.y > bottom ? point.y : bottom;
                
            }
            
            /**对象位置*/
            pan.rcRect.top = top;
            pan.rcRect.right = right;
            pan.rcRect.bottom = bottom;
            pan.rcRect.left = left;
            
            /**数据大小*/
            pan.dwDataSize = (10 + 2 * pan.nCount) * 4;
            int len = (13 + 2 * pan.nCount) * 4;
            //用结构体去接收data数据
            NSData *data = [NSData dataWithBytes:&pan length:len];
            
            [self.delegate panDrawView:self andData:data];
        }
        
        //重绘
        [self setNeedsDisplay];
    }
    
}

- (int)initPathID {
    NSDate *senddate = [NSDate date];
    
    return (int)[senddate timeIntervalSince1970];
}


- (NSData *)whiteData {
    
    
    
    
    return  nil;
}

/**画椭圆、矩形*/
- (void)iconWithRect:(CGRect)rect andType:(DrawType)type andPathID:(int)pathID {
    //1.创建path
    MyBezierPath *path = [MyBezierPath bezierPathWithRect:rect andType:type];
    //2.扩展属性，方便后面移动
    path.rect = rect;
    path.type = type;
    path.pathID = pathID;
    path.isFill = type > DrawTypeFill;
    path.color = self.color;
    path.lineWidth = self.width;
    self.path = path;
    //加入到path数组中
    [self.allPathArray addObject:path];
    
    //redraw the view
    [self setNeedsDisplay];

}

/**
 *  根据 点集 绘图
 *
 *  @param points <#points description#>
 *  @param pathID <#pathID description#>
 */
- (void)drawWithPoints:(NSArray *)points andPathID:(int)pathID {
    
    
    MyBezierPath *path = [[MyBezierPath alloc] init];
    self.path = path;
    
    path.pathID = pathID;
    path.points = points;
    path.type = DrawTypePoints;
    path.color = self.color;
    path.lineWidth = self.width;
    
//    path.lineWidth = 2;
    SCPoint *point = points[0];
    [self.path moveToPoint:CGPointMake(point.x, point.y)];
    
    [self.allPathArray addObject:path];
    
    for (int i = 1; i < points.count; i++) {
    
        SCPoint *point = points[i];

        [self.path addLineToPoint:CGPointMake(point.x, point.y)];
        
    }
    
    //redraw the view
    [self setNeedsDisplay];
    
}
/**
 *  白板页控制
 *
 *  @param pageNum 白板页码
 *  @param type    操作类型
 */
- (void)pageControlWithPageNum:(int)pageNum andControlType:(char)type {
    
    if (type == 1) {
        //新增白板页
        //1.新建一个数组 加入白板数组
        //2.将当前绘制数组切换成新的数组
        //3.刷新白板页
        NSMutableArray *array = [NSMutableArray array];
        
        [self.allPagePathArray addObject:array];;
        
        self.allPathArray = array;
        
        [self setNeedsDisplay];
        
    } else if (type == 2) {
        //切换白板页
        //1.根据pageNum切换成当前数组
        //2.刷新白板页
        if (self.allPagePathArray.count == 0 || pageNum > self.allPagePathArray.count) {
            return;
        }
        
        self.allPathArray = self.allPagePathArray[pageNum];
        
        [self setNeedsDisplay];
        
    } else {
        //其他
        
        
    }
    
    
}



-(void)drawRect:(CGRect)rect {
    
    //绘制保存的所有路径
    for (MyBezierPath *path in self.allPathArray) {
        //判断取出的路径真实类型
        if([path isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)path;
            [image drawInRect:CGRectMake(0, 0, 10, 10)];
        } else if([path isKindOfClass:[UILabel class]]) {
            //
            UILabel *label = (UILabel *)path;
            
//            label.frame = CGRectMake(100, 100, 100, 100);
//            label.backgroundColor = [UIColor redColor];
//
            [label drawRect:rect];
        } else if ([path isKindOfClass:[SCPicture class]]) {
            SCPicture *picture = (SCPicture *)path;
            [picture.image drawInRect:picture.rect];

        } else {
            //设置线条颜色
            [path.color set];
            //[path setLineWidth:self.width];
            [path stroke];
            //设置填充
            if (path.isFill) {
                [path.fillColor setFill];
                [path fill];
            }
//
        }
      
    }
    
}

@end
