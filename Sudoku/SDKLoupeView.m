//
//  SDKLoupeView.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKLoupeView.h"
#import "SDKTheme.h"

static const CGFloat kSDKLoupeDiameter = 148.0;

@interface SDKLoupeView ()
- (CGPoint)clampCenter:(CGPoint)center;
@end

@implementation SDKLoupeView {
    CGPoint _boardPoint;
    CGFloat _cellSize;
    BOOL _visible;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.userInteractionEnabled = NO;
        _magnification = 2.15;
        _cellSize = 34.0;
        _focusIndex = -1;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowRadius = 16.0;
        self.layer.shadowOffset = CGSizeMake(0, 8);
    }
    return self;
}

#pragma mark - Presentation

- (BOOL)isVisible { return _visible; }

- (void)presentInHost:(UIView *)host
                center:(CGPoint)center
            boardPoint:(CGPoint)boardPoint
              cellSize:(CGFloat)cellSize
                  game:(SDKGameState *)game
            focusIndex:(NSInteger)focusIndex {
    if (!host) return;
    self.game = game;
    _boardPoint = boardPoint;
    _cellSize = MAX(cellSize, 1.0);
    self.focusIndex = focusIndex;
    self.bounds = CGRectMake(0, 0, kSDKLoupeDiameter, kSDKLoupeDiameter);
    self.center = [self clampCenter:center];

    if (self.superview != host) {
        [self removeFromSuperview];
        [host addSubview:self];
    }
    [self setNeedsDisplay];

    if (!_visible) {
        _visible = YES;
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.55, 0.55);
        [UIView animateWithDuration:0.30
                              delay:0
             usingSpringWithDamping:0.62
              initialSpringVelocity:0.6
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            self.alpha = 1.0;
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)updateCenter:(CGPoint)center
          boardPoint:(CGPoint)boardPoint
            cellSize:(CGFloat)cellSize
          focusIndex:(NSInteger)focusIndex {
    _boardPoint = boardPoint;
    _cellSize = MAX(cellSize, 1.0);
    self.focusIndex = focusIndex;

    CGPoint target = [self clampCenter:center];
    [UIView animateWithDuration:0.10
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear
                     animations:^{
        self.center = target;
    } completion:nil];
    [self setNeedsDisplay];
}

- (void)hideAnimated:(BOOL)animated {
    if (!_visible) return;
    _visible = NO;
    void (^cleanup)(BOOL) = ^(BOOL finished) {
        // A new presentation may have started during the fade-out: keep it alive.
        if (self->_visible) return;
        [self removeFromSuperview];
    };
    if (animated) {
        [UIView animateWithDuration:0.18 animations:^{
            self.alpha = 0.0;
            self.transform = CGAffineTransformMakeScale(0.80, 0.80);
        } completion:cleanup];
    } else {
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.80, 0.80);
        cleanup(YES);
    }
}

- (void)setFocusIndex:(NSInteger)focusIndex {
    _focusIndex = focusIndex;
    [self setNeedsDisplay];
}

- (CGPoint)clampCenter:(CGPoint)center {
    CGFloat half = kSDKLoupeDiameter / 2.0;
    UIView *host = self.superview;
    if (!host) return center;
    CGPoint target = center;
    CGFloat w = CGRectGetWidth(host.bounds);
    CGFloat h = CGRectGetHeight(host.bounds);
    target.x = MAX(half + 4.0, MIN(w - half - 4.0, target.x));
    target.y = MAX(half + 4.0, MIN(h - half - 4.0, target.y));
    return target;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat pad = 5.0;
    CGRect circle = CGRectInset(self.bounds, pad, pad);

    // ---- content, clipped to the glass circle ---------------------------
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, circle);
    CGContextClip(ctx);

    [[UIColor colorWithWhite:0.02 alpha:0.94] setFill];
    CGContextFillRect(ctx, circle);

    if (self.game) {
        CGFloat m = self.magnification;
        CGFloat cs = _cellSize * m;
        CGPoint c = CGPointMake(CGRectGetMidX(circle), CGRectGetMidY(circle));
        CGFloat ox = c.x - _boardPoint.x * m;
        CGFloat oy = c.y - _boardPoint.y * m;

        NSInteger focus = self.focusIndex;
        NSInteger focusValue = (focus >= 0) ? [self.game valueAtIndex:focus] : 0;

        // row / column / box glow of the focused cell
        if (focus >= 0) {
            NSInteger fr = focus / 9, fc = focus % 9;
            NSInteger boxRow = (fr / 3) * 3, boxCol = (fc / 3) * 3;
            for (NSInteger i = 0; i < 81; i++) {
                NSInteger r = i / 9, col = i % 9;
                BOOL peer = (r == fr || col == fc ||
                             (r >= boxRow && r < boxRow + 3 && col >= boxCol && col < boxCol + 3));
                if (!peer) continue;
                if (i == focus) continue;
                [[SDKTheme cellPeer] setFill];
                CGContextFillRect(ctx, CGRectMake(ox + col * cs, oy + r * cs, cs, cs));
            }
        }

        // cell content
        UIFont *digitFont = [SDKTheme roundedFont:cs * 0.54 weight:UIFontWeightBold];
        UIFont *noteFont = [SDKTheme roundedFont:cs * 0.21 weight:UIFontWeightSemibold];
        NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        para.alignment = NSTextAlignmentCenter;

        for (NSInteger i = 0; i < 81; i++) {
            NSInteger r = i / 9, col = i % 9;
            CGRect cellRect = CGRectMake(ox + col * cs, oy + r * cs, cs, cs);
            if (!CGRectIntersectsRect(cellRect, circle)) continue;

            if (focusValue != 0 && [self.game valueAtIndex:i] == focusValue && i != focus) {
                [[SDKTheme cellSame] setFill];
                CGContextFillRect(ctx, cellRect);
            }

            NSInteger v = [self.game valueAtIndex:i];
            if (v > 0) {
                BOOL given = [self.game isGivenAtIndex:i];
                UIColor *color = given ? [SDKTheme givenText] : [SDKTheme userText];
                if ([self.game isWrongAtIndex:i]) color = [SDKTheme errorText];
                NSDictionary *attrs = @{ NSFontAttributeName: digitFont,
                                         NSForegroundColorAttributeName: color,
                                         NSParagraphStyleAttributeName: para };
                NSString *str = [NSString stringWithFormat:@"%ld", (long)v];
                CGSize size = [str sizeWithAttributes:attrs];
                [str drawInRect:CGRectMake(CGRectGetMidX(cellRect) - size.width / 2.0,
                                           CGRectGetMidY(cellRect) - size.height / 2.0,
                                           size.width, size.height)
                 withAttributes:attrs];
            } else {
                NSUInteger mask = [self.game noteMaskAtIndex:i];
                if (mask == 0) continue;
                NSDictionary *attrs = @{ NSFontAttributeName: noteFont,
                                         NSForegroundColorAttributeName: [SDKTheme noteText],
                                         NSParagraphStyleAttributeName: para };
                CGFloat third = cs / 3.0;
                for (NSInteger d = 1; d <= 9; d++) {
                    if ((mask & (1u << (NSUInteger)(d - 1))) == 0) continue;
                    CGRect mini = CGRectMake(CGRectGetMinX(cellRect) + ((d - 1) % 3) * third,
                                             CGRectGetMinY(cellRect) + ((d - 1) / 3) * third,
                                             third, third);
                    NSString *str = [NSString stringWithFormat:@"%ld", (long)d];
                    CGSize size = [str sizeWithAttributes:attrs];
                    [str drawInRect:CGRectMake(CGRectGetMidX(mini) - size.width / 2.0,
                                               CGRectGetMidY(mini) - size.height / 2.0,
                                               size.width, size.height)
                     withAttributes:attrs];
                }
            }
        }

        // grid lines
        CGContextSetLineWidth(ctx, 0.9);
        CGContextSetStrokeColorWithColor(ctx, [[UIColor colorWithWhite:1.0 alpha:0.12] CGColor]);
        for (NSInteger i = 0; i <= 9; i++) {
            CGFloat x = ox + cs * i;
            CGFloat y = oy + cs * i;
            CGContextMoveToPoint(ctx, x, oy);
            CGContextAddLineToPoint(ctx, x, oy + cs * 9.0);
            CGContextStrokePath(ctx);
            CGContextMoveToPoint(ctx, ox, y);
            CGContextAddLineToPoint(ctx, ox + cs * 9.0, y);
            CGContextStrokePath(ctx);
        }

        // focused cell frame
        if (focus >= 0) {
            NSInteger fr = focus / 9, fc = focus % 9;
            CGRect frame = CGRectInset(CGRectMake(ox + fc * cs, oy + fr * cs, cs, cs), cs * 0.06, cs * 0.06);
            UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:cs * 0.16];
            [[[SDKTheme accent] colorWithAlphaComponent:0.95] setStroke];
            p.lineWidth = MAX(2.0, cs * 0.05);
            [p stroke];
        }
    }

    // subtle vignette so edges read as glass
    CGContextRestoreGState(ctx);

    // ---- rim --------------------------------------------------------------
    UIBezierPath *rim = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(circle, 0.75, 0.75)];
    [[UIColor colorWithWhite:1.0 alpha:0.50] setStroke];
    rim.lineWidth = 1.5;
    [rim stroke];

    UIBezierPath *inner = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(circle, 3.0, 3.0)];
    [[UIColor colorWithWhite:0.0 alpha:0.30] setStroke];
    inner.lineWidth = 2.0;
    [inner stroke];

    // top gloss arc: a soft highlight that sells the glass
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, circle);
    CGContextClip(ctx);
    CGRect gloss = CGRectMake(CGRectGetMinX(circle),
                              CGRectGetMinY(circle),
                              CGRectGetWidth(circle),
                              CGRectGetHeight(circle) * 0.52);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGFloat components[8] = { 1, 1, 1, 0.16, 1, 1, 1, 0.0 };
    CGFloat locations[2] = { 0.0, 1.0 };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(space, components, locations, 2);
    CGContextDrawLinearGradient(ctx, gradient,
                                CGPointMake(CGRectGetMidX(gloss), CGRectGetMinY(gloss)),
                                CGPointMake(CGRectGetMidX(gloss), CGRectGetMaxY(gloss)),
                                0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);
}

@end
