//
//  SVGClipsImageView.m
//  SVGClipsImage
//
//  Created by lax on 2022/6/21.
//

#import "SVGClipsImageView.h"
#import "PocketSVG.h"

@interface SVGClipsImageView ()

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIImageView *imageView;

// 蒙层
@property (nonatomic, strong) CAShapeLayer *maskLayer;

@property (nonatomic, copy) NSString *filepath;

@end

@implementation SVGClipsImageView

- (NSString *)filepath {
    if (!_filepath) {
        _filepath = [[NSBundle mainBundle] pathForResource:@"爱心" ofType:@"svg"];
    }
    return _filepath;
}

- (CAShapeLayer *)maskLayer {
    if (!_maskLayer) {
        _maskLayer = [[CAShapeLayer alloc] init];
        _maskLayer.fillRule = kCAFillRuleEvenOdd;
        _maskLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    }
    return _maskLayer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        UIImage *image = [UIImage imageNamed:@"image"];
        
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.delegate = self;
        self.scrollView.frame = CGRectMake(100, 200, 175, 175 / image.size.width * image.size.height);
        self.scrollView.backgroundColor = [UIColor orangeColor];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.alwaysBounceVertical = YES;
        self.scrollView.alwaysBounceHorizontal = YES;
        self.scrollView.bounces = NO;
        self.scrollView.bouncesZoom = NO;
        self.scrollView.minimumZoomScale = 1;
        self.scrollView.maximumZoomScale = 5;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        [self addSubview:self.scrollView];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.frame = self.scrollView.bounds;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor greenColor];
        self.imageView.image = image;
        [self.scrollView addSubview:self.imageView];
        
        [self.layer addSublayer:self.maskLayer];
        [self drawMaskLayer];
        
    }
    return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return self.scrollView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

// 宽高适配
- (CGRect)adaptionSize:(CGSize)size edgInsets:(UIEdgeInsets)edgInsets image:(UIImage *)image aspectFit:(BOOL)aspectFit needOrigin:(BOOL)needOrigin {
    CGFloat limitW = size.width - edgInsets.left - edgInsets.right;
    CGFloat limitH = size.height - edgInsets.top - edgInsets.bottom;
    CGFloat limitScale = limitW / limitH;
    CGFloat scale = image.size.width / image.size.height;
    CGFloat w = 0;
    CGFloat h = 0;
    if (aspectFit ? scale > limitScale : scale < limitScale) {
        w = limitW;
        h = limitW / image.size.width * image.size.height;
    } else {
        w = limitH / image.size.height * image.size.width;
        h = limitH;
    }
    return needOrigin ? CGRectMake(edgInsets.left + (limitW - w) / 2, edgInsets.top + (limitH - h) / 2, w, h) : CGRectMake(0, 0, w, h);
}

// 绘制蒙层
-(void)drawMaskLayer {
    
    SVGBezierPath *svgPath = [SVGBezierPath pathsFromSVGAtURL:[NSURL fileURLWithPath:self.filepath]].firstObject;
    
    CGSize svgSize = SVGBoundingRectForPaths(@[svgPath]).size;
    
    // 根据svg图形显示scrollview和imageview
    self.scrollView.frame = CGRectMake(100, 200, 200, 200 * svgSize.height / svgSize.width);
    self.imageView.frame = [self adaptionSize:self.scrollView.bounds.size edgInsets:UIEdgeInsetsZero image:self.imageView.image aspectFit:NO needOrigin:NO];
    self.scrollView.contentSize = self.imageView.frame.size;
    
    CGRect drawRect = self.scrollView.frame;
    CGFloat scaleWidth = drawRect.size.width / svgSize.width;
    CGFloat scaleHeight = drawRect.size.height / svgSize.height;
    CGAffineTransform pathTransform = CGAffineTransformConcat(CGAffineTransformMakeTranslation(drawRect.origin.x / scaleWidth, drawRect.origin.y / scaleHeight), CGAffineTransformMakeScale(scaleWidth , scaleHeight));
    CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(svgPath.CGPath, &pathTransform);
    
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithCGPath:transformedPath];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:UIScreen.mainScreen.bounds];
    [path appendPath:clipPath];
    
    self.maskLayer.path = path.CGPath;

}

// 裁剪图片
- (UIImage *)clipImage {
    
    SVGBezierPath *svgPath = [SVGBezierPath pathsFromSVGAtURL:[NSURL fileURLWithPath:self.filepath]].firstObject;
    
    CGSize svgSize = SVGBoundingRectForPaths(@[svgPath]).size;
    CGFloat imageScale = self.imageView.frame.size.width / self.imageView.image.size.width;
    CGFloat svgWidth = self.scrollView.frame.size.width / imageScale;
    CGFloat svgHeight = svgSize.height * svgWidth / svgSize.width;
    // 计算svg缩放比
    CGAffineTransform pathTransform = CGAffineTransformMakeScale(svgWidth / svgSize.width, svgHeight / svgSize.height);
    CGPathRef transformedPath = CGPathCreateCopyByTransformingPath(svgPath.CGPath, &pathTransform);
    UIBezierPath *path = [UIBezierPath bezierPathWithCGPath:transformedPath];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(svgWidth, svgHeight), NO, 1.0);
    [path addClip];
    
    // 计算绘制位置
    CGFloat svgX = self.scrollView.contentOffset.x / imageScale;
    CGFloat svgY = self.scrollView.contentOffset.y / imageScale;
    [self.imageView.image drawAtPoint:CGPointMake(-svgX, -svgY)];
    
    // 生成裁切后的图片
    UIImage *clipImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return clipImage;
}

@end
