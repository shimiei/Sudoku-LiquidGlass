//
//  SDKLoupeView.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKLoupeView.h"
#import "SDKBoardView.h"
#import "SDKTheme.h"

@interface SDKLoupeView ()
@property (nonatomic, weak, nullable) SDKBoardView *board;
@property (nonatomic) NSInteger focusIndex;
@property (nonatomic) BOOL visible;
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
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.18;
        self.layer.shadowRadius = 10.0;
        self.layer.shadowOffset = CGSizeMake(0, 4);
    }
    return self;
}

- (void)setDiameter:(CGFloat)diameter {
    _diameter = MAX(60.0, diameter);
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    self.layer.shadowPath = circle.CGPath;
}

#pragma mark - Presentation

- (void)showInHost:(UIView *)host atCenter:(CGPoint)center board:(SDKBoardView *)board focusIndex:(NSInteger)index {
    if (!host) return;
    self.board = board;
    self.focusIndex = index;
    self.bounds = CGRectMake(0, 0, self.diameter, self.diameter);
    self.center = [self clampedCenter:center];
    if (self.superview != host) {
        [self removeFromSuperview];
        [host addSubview:self];
    }
    [host bringSubviewToFront:self];
    [self setNeedsDisplay];

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
        [self setNeedsDisplay];
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

- (CGPoint)clampedCenter:(CGPoint)center {
    CGFloat half = self.diameter / 2.0;
    UIView *host = self.superview;
    if (!host) return center;
    CGFloat w = CGRectGetWidth(host.bounds);
    CGFloat h = CGRectGetHeight(host.bounds);
    return CGPointMake(MAX(half + 4.0, MIN(w - half - 4.0, center.x)),
                       MAX(half + 4.0, MIN(h - half - 4.0, center.y)));
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGRect circle = CGRectInset(self.bounds, 1.5, 1.5);
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, circle);
    CGContextClip(ctx);

    CGContextSetFillColorWithColor(ctx, [SDKTheme cgColor:[SDKTheme boardBackground] traits:self.traitCollection]);
    CGContextFillRect(ctx, self.bounds);

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

    // rim
    CGContextSetLineWidth(ctx, 3.0);
    CGContextSetStrokeColorWithColor(ctx, [SDKTheme cgColor:[UIColor separatorColor] traits:self.traitCollection]);
    CGContextStrokeEllipseInRect(ctx, circle);
}

@end
