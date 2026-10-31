//
//  SDKLoupeView.m
//  Sudoku
//
//  结构（iOS 26）：
//    SDKLoupeView   容器：投影、按宿主边界收敛、显隐动画
//      └ 玻璃圆形       UIGlassEffect（系统渲染的液态玻璃）
//      └ SDKLoupeCanvas 把棋盘的绘制代码按 CTM 放大重绘，矢量清晰
//  旧系统没有玻璃时，canvas 自己铺一层棋盘底色，外观依旧成立。
//

#import "SDKLoupeView.h"
#import "SDKBoardView.h"
#import "SDKMaterial.h"
#import "SDKTheme.h"

#pragma mark - Canvas

@interface SDKLoupeCanvas : UIView
@property (nonatomic, weak, nullable) SDKBoardView *board;
@property (nonatomic) NSInteger focusIndex;
@property (nonatomic) CGFloat magnification;
@property (nonatomic) BOOL glassBackdrop;
@end

@implementation SDKLoupeCanvas

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGRect circle = CGRectInset(self.bounds, 1.0, 1.0);
    if (CGRectGetWidth(circle) < 4.0) return;

    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, circle);
    CGContextClip(ctx);

    if (!self.glassBackdrop) {
        CGContextSetFillColorWithColor(ctx,
            [SDKTheme cgColor:[SDKTheme boardBackground] traits:self.traitCollection]);
        CGContextFillRect(ctx, self.bounds);
    }

    SDKBoardView *board = self.board;
    if (board && self.focusIndex >= 0 && self.focusIndex <= 80) {
        CGRect grid = [board gridRect];
        CGPoint focus = [board centerForIndex:self.focusIndex];
        CGFloat m = MAX(1.0, self.magnification);
        CGContextTranslateCTM(ctx, CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        CGContextScaleCTM(ctx, m, m);
        CGContextTranslateCTM(ctx, -focus.x, -focus.y);
        [board drawGridInRect:grid context:ctx];
    }
    CGContextRestoreGState(ctx);

    // 一圈细边：玻璃自带高光，这里只补一道收边
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetStrokeColorWithColor(ctx,
        [SDKTheme cgColor:[UIColor separatorColor] traits:self.traitCollection]);
    CGContextStrokeEllipseInRect(ctx, circle);
}

@end

#pragma mark - Loupe

@interface SDKLoupeView ()
@property (nonatomic, weak, nullable) SDKBoardView *board;
@property (nonatomic) NSInteger focusIndex;
@property (nonatomic, readwrite) BOOL visible;
@property (nonatomic, strong) SDKLoupeCanvas *canvas;
@property (nonatomic, strong, nullable) UIView *glass;
@end

@implementation SDKLoupeView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _diameter = 132.0;
        _magnification = 2.1;
        _focusIndex = -1;

        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.userInteractionEnabled = NO;

        _glass = [SDKMaterial glassCircleWithDiameter:_diameter];
        if (_glass) [self addSubview:_glass];

        _canvas = [[SDKLoupeCanvas alloc] initWithFrame:self.bounds];
        _canvas.glassBackdrop = (_glass != nil);
        _canvas.magnification = _magnification;
        [self addSubview:_canvas];

        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.20;
        self.layer.shadowRadius = 12.0;
        self.layer.shadowOffset = CGSizeMake(0, 5);
    }
    return self;
}

- (void)setDiameter:(CGFloat)diameter {
    _diameter = MAX(60.0, diameter);
    [self setNeedsLayout];
    [self.canvas setNeedsDisplay];
}

- (void)setMagnification:(CGFloat)magnification {
    _magnification = MAX(1.0, magnification);
    self.canvas.magnification = _magnification;
    [self.canvas setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.glass.frame = self.bounds;
    self.glass.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0;
    self.canvas.frame = self.bounds;
    self.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
}

#pragma mark - Presentation

- (void)showInHost:(UIView *)host atCenter:(CGPoint)center board:(SDKBoardView *)board focusIndex:(NSInteger)index {
    if (!host) return;
    self.board = board;
    self.focusIndex = index;
    self.bounds = CGRectMake(0, 0, self.diameter, self.diameter);
    [self syncCanvas];
    if (self.superview != host) {
        [self removeFromSuperview];
        [host addSubview:self];
    }
    [host bringSubviewToFront:self];
    // Clamp after insertion: clampedCenter: needs host bounds via superview.
    self.center = [self clampedCenter:center];

    if (!self.visible) {
        self.visible = YES;
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.88, 0.88);
        [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.alpha = 1.0;
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)moveToCenter:(CGPoint)center board:(SDKBoardView *)board focusIndex:(NSInteger)index {
    self.board = board;
    if (index != self.focusIndex) {
        self.focusIndex = index;
        [self syncCanvas];
    }
    CGPoint target = [self clampedCenter:center];
    if (fabs(target.x - self.center.x) > 0.1 || fabs(target.y - self.center.y) > 0.1) {
        self.center = target;
    }
}

- (void)hide {
    if (!self.visible) {
        [self removeFromSuperview];
        return;
    }
    self.visible = NO;
    [UIView animateWithDuration:0.12 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (self.visible) return;   // re-presented during the fade-out
        [self removeFromSuperview];
    }];
}

- (void)syncCanvas {
    self.canvas.board = self.board;
    self.canvas.focusIndex = self.focusIndex;
    self.canvas.magnification = self.magnification;
    [self.canvas setNeedsDisplay];
}

- (CGPoint)clampedCenter:(CGPoint)center {
    CGFloat half = self.diameter / 2.0;
    UIView *host = self.superview;
    if (!host) return center;
    CGFloat w = CGRectGetWidth(host.bounds);
    CGFloat h = CGRectGetHeight(host.bounds);
    return CGPointMake(MAX(half + 4.0, MIN(w - half - 4.0, center.x)),
                       MAX(half + 4.0, MIN(h - half - 4.0, center.y)));
}

@end
