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
@property (nonatomic, strong) UIBezierPath *path;

//保存当前绘制的所有路径
@property (nonatomic, strong) NSMutableArray *allPathArray;

//当前路径的线宽
@property (nonatomic, assign) CGFloat width;

//当前路径的颜色
@property (nonatomic, strong) UIColor *color;

@end

@implementation DrawView


- (NSMutableArray *)allPathArray {
    
    if (_allPathArray == nil) {
        _allPathArray = [NSMutableArray array];
    }
    return _allPathArray;
}


- (void)awakeFromNib {
    //添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    self.width = 1;
    self.color = [UIColor blackColor];
}


-(void)setImage:(UIImage *)image {
    _image = image;
    
  
    //添加图片添加到数组当中
    [self.allPathArray addObject:image];
    //重绘
    [self setNeedsDisplay];
    
}

- (void)drawWithFontText:(NSString *)text andRect:(CGRect)rect andPathID:(int)pathID{
    
    //1.把当前的View做一个截屏
    //画布大小
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    //2.获得一个位图图形上下文
    CGContextRef context=UIGraphicsGetCurrentContext();
    
    CGContextDrawPath(context, kCGPathStroke);

    //3.想要添加的文字
    [text drawAtPoint:CGPointMake(rect.origin.x, rect.origin.y) withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:40],NSForegroundColorAttributeName:self.color}];
    
    
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
    [self setLineColor:[UIColor whiteColor]];
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
                    [self.allPathArray removeObjectAtIndex:i];
                    //2.
                    CGRect newRect = picture.rect;
                    newRect = CGRectMake(picture.rect.origin.x + point.x, picture.rect.origin.y + point.y, picture.rect.size.width, picture.rect.size.height);
                    
                    self.color = picture.color;
                    
                    [self drawWithFontText:picture.text andRect:newRect andPathID:pathID ];
                    
                    break;
                }
            
            }else if ([self.allPathArray[i] isKindOfClass:[MyBezierPath class]]) {
                //路径
                MyBezierPath *path = self.allPathArray[i];
                
                if (path.pathID == pathID) {
                    //找到对象
                    //找到的对象分成继红类型：点线、矩形、椭圆、直线、文字、图片。。。
                    if (path.type == DrawTypeRectangle || path.type == DrawTypeEllipse || path.type == DrawTypeEllipseFill || path.type == DrawTypeRectangleFill) {
                        //矩阵
                        CGRect rect = path.rect;
                        rect.origin.x = path.rect.origin.x + point.x;
                        rect.origin.y = path.rect.origin.y + point.y;
                        MyBezierPath *newPath = [MyBezierPath bezierPathWithRect:rect andType:path.type];
                        
                        [newPath setProperyeWithPath:path andNewRect:rect];
                        
                        [self.allPathArray removeObjectAtIndex:i];
                        
                        [self.allPathArray addObject:newPath];
                  
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
                        self.path = newPath;
                        newPath.color = path.color;
                        newPath.pathID = pathID;
                        newPath.points = newPoints;
                        newPath.lineWidth = path.lineWidth;
                        SCPoint *point = points[0];
                        [self.path moveToPoint:CGPointMake(point.x / 2.0, point.y / 2.0)];
                        
                        
                        
                        for (int i = 1; i < points.count; i++) {
                            
                            SCPoint *point = points[i];
                            
                            [self.path addLineToPoint:CGPointMake(point.x / 2.0, point.y / 2.0)];
                        }
                        
                        [self.allPathArray removeObjectAtIndex:i];
                        
                        [self.allPathArray addObject:newPath];
                        
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
                    
                    [self.allPathArray removeObjectAtIndex:i];
                    
                    [self.allPathArray addObject:path];
                    
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
                    
                    [self.allPathArray removeObjectAtIndex:i];
                    
                    [self.allPathArray addObject:path];
                    
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
                
                [self.allPathArray removeObjectAtIndex:i];
                
                [self.allPathArray addObject:newPath];
                
                [self setNeedsDisplay];
                
                break;
            }
           
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



- (void)moveLine {
    MyBezierPath *path = self.allPathArray.firstObject;
//    [path moveToPoint:CGPointMake(0, 0)];
    [path bezierPathByReversingPath];
    [self.allPathArray replaceObjectAtIndex:0 withObject:path];
    
    [self setNeedsDisplay];
}

- (void)pan:(UIPanGestureRecognizer *)pan {
    
    //获取的当前手指的点
    CGPoint curP = [pan locationInView:self];
    //判断手势的状态
    if(pan.state == UIGestureRecognizerStateBegan) {
        //创建路径
        //UIBezierPath *path = [UIBezierPath bezierPath];
        MyBezierPath *path = [[MyBezierPath alloc] init];
        self.path = path;
        //设置起点
        [path moveToPoint:curP];
        
        //设置线的宽度
        [path setLineWidth:self.width];
        //设置线的颜色
        //什么情况下自定义类:当发现系统原始的功能,没有办法瞒足自己需求时,这个时候,要自定义类.继承系统原来的东西.再去添加属性自己的东西.
        path.color = self.color;
        
        [self.allPathArray addObject:path];
        
    } else if(pan.state == UIGestureRecognizerStateChanged) {
        
        //绘制一根线到当前手指所在的点
        [self.path addLineToPoint:curP];
        //重绘
        [self setNeedsDisplay];
    }
    
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
    [self.path moveToPoint:CGPointMake(point.x / 2.0, point.y / 2.0)];
    
    [self.allPathArray addObject:path];
    
    for (int i = 1; i < points.count; i++) {
    
        SCPoint *point = points[i];

        [self.path addLineToPoint:CGPointMake(point.x / 2.0, point.y / 2.0)];
        
    }
    
    //redraw the view
    [self setNeedsDisplay];
    
}

-(void)drawRect:(CGRect)rect {
    
    //绘制保存的所有路径
    for (MyBezierPath *path in self.allPathArray) {
        //判断取出的路径真实类型
        if([path isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)path;
            [image drawInRect:rect];
        } else if([path isKindOfClass:[UILabel class]]) {
            //
            UILabel *label = (UILabel *)path;
            
//            label.frame = CGRectMake(100, 100, 100, 100);
//            label.backgroundColor = [UIColor redColor];
//
            [label drawRect:rect];
        } else if ([path isKindOfClass:[SCPicture class]]) {
            SCPicture *picture = (SCPicture *)path;
            [picture.image drawInRect:rect];

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
