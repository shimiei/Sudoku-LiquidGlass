//
//  SDKBoardView.m
//  Sudoku — Liquid Glass Edition
//

#import "SDKBoardView.h"
#import "SDKTheme.h"

@interface SDKBoardView ()
@property (nonatomic, strong) CAShapeLayer *selectionRing;
- (void)updateSelectionRingAnimated:(BOOL)animated;
- (BOOL)cellIsError:(NSInteger)index;
@end

@implementation SDKBoardView {
    BOOL _tracking;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
        self.contentInset = 7.0;
        _selectedIndex = -1;
        _highlightSameNumbers = YES;
        _highlightPeers = YES;
        _showConflicts = YES;
        _autoCheck = NO;

        _selectionRing = [CAShapeLayer layer];
        _selectionRing.fillColor = [UIColor clearColor].CGColor;
        _selectionRing.strokeColor = [[SDKTheme accent] colorWithAlphaComponent:0.95].CGColor;
        _selectionRing.lineWidth = 2.0;
        _selectionRing.opacity = 0.0;
        _selectionRing.shadowColor = [SDKTheme accent].CGColor;
        _selectionRing.shadowOpacity = 0.85;
        _selectionRing.shadowRadius = 7.0;
        _selectionRing.shadowOffset = CGSizeZero;
        [self.layer addSublayer:_selectionRing];
    }
    return self;
}

#pragma mark - Geometry

- (CGFloat)cellSize {
    CGFloat side = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) - self.contentInset * 2.0;
    return MAX(1.0, side / 9.0);
}

- (CGPoint)gridOrigin {
    CGFloat side = [self cellSize] * 9.0;
    return CGPointMake((CGRectGetWidth(self.bounds) - side) / 2.0,
                       (CGRectGetHeight(self.bounds) - side) / 2.0);
}

- (CGRect)rectForCellAtIndex:(NSInteger)index {
    if (index < 0 || index > 80) return CGRectZero;
    CGFloat s = [self cellSize];
    CGPoint o = [self gridOrigin];
    NSInteger row = index / 9, col = index % 9;
    return CGRectMake(o.x + col * s, o.y + row * s, s, s);
}

- (nullable NSValue *)cellCenterValueAtIndex:(NSInteger)index {
    if (index < 0 || index > 80) return nil;
    CGRect r = [self rectForCellAtIndex:index];
    return [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r))];
}

- (NSInteger)indexForPoint:(CGPoint)point {
    CGFloat s = [self cellSize];
    CGPoint o = [self gridOrigin];
    CGFloat x = point.x - o.x;
    CGFloat y = point.y - o.y;
    if (x < 0 || y < 0 || x >= s * 9.0 || y >= s * 9.0) return -1;
    NSInteger col = (NSInteger)floor(x / s);
    NSInteger row = (NSInteger)floor(y / s);
    col = MAX(0, MIN(8, col));
    row = MAX(0, MIN(8, row));
    return row * 9 + col;
}

#pragma mark - State

- (void)setGame:(SDKGameState *)game {
    _game = game;
    self.selectedIndex = -1;
    [self setNeedsDisplay];
}

- (void)reloadData {
    [self setNeedsDisplay];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < -1 || selectedIndex > 80) selectedIndex = -1;
    BOOL changed = (selectedIndex != _selectedIndex);
    _selectedIndex = selectedIndex;
    [self setNeedsDisplay];
    if (changed) [self updateSelectionRingAnimated:YES];
}

- (BOOL)cellIsError:(NSInteger)index {
    if (!self.game) return NO;
    if ([self.game valueAtIndex:index] == 0) return NO;
    if (self.showConflicts && [self.game hasConflictAtIndex:index]) return YES;
    if (self.autoCheck && [self.game isWrongAtIndex:index]) return YES;
    return NO;
}

#pragma mark - Selection ring

- (void)updateSelectionRingAnimated:(BOOL)animated {
    if (_selectedIndex < 0) {
        if (_selectionRing.opacity > 0.01) {
            CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fade.fromValue = @(_selectionRing.opacity);
            fade.toValue = @(0.0);
            fade.duration = 0.16;
            _selectionRing.opacity = 0.0;
            [_selectionRing addAnimation:fade forKey:@"fade"];
        }
        return;
    }

    CGRect r = CGRectInset([self rectForCellAtIndex:_selectedIndex], 1.5, 1.5);
    CGFloat radius = MAX(7.0, [self cellSize] * 0.20);
    UIBezierPath *bezier = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:radius];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _selectionRing.lineWidth = MAX(1.6, MIN(2.8, [self cellSize] * 0.045));
    if (_selectionRing.path != NULL && animated) {
        CGPathRef oldPath = CGPathCreateCopy(_selectionRing.path);
        _selectionRing.path = bezier.CGPath;
        if (oldPath) {
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
            anim.fromValue = (__bridge id)oldPath;
            anim.toValue = (__bridge id)bezier.CGPath;
            anim.duration = 0.20;
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            [_selectionRing addAnimation:anim forKey:@"path"];
            CGPathRelease(oldPath);
        }
    } else {
        _selectionRing.path = bezier.CGPath;
    }
    _selectionRing.opacity = 1.0;
    [CATransaction commit];
}

#pragma mark - Drawing

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateSelectionRingAnimated:NO];
}

- (void)drawRect:(CGRect)rect {
    if (!self.game) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat s = [self cellSize];
    if (s < 3.0) return;

    CGPoint o = [self gridOrigin];
    CGRect gridRect = CGRectMake(o.x, o.y, s * 9.0, s * 9.0);
    NSInteger sel = self.selectedIndex;
    NSInteger selValue = (sel >= 0) ? [self.game valueAtIndex:sel] : 0;

    // Soft wash behind the grid.
    [[UIColor colorWithWhite:1.0 alpha:0.025] setFill];
    CGContextFillRect(ctx, gridRect);

    // ---- highlights -------------------------------------------------------
    UIColor *peerColor = [SDKTheme cellPeer];
    UIColor *sameColor = [SDKTheme cellSame];
    UIColor *errorColor = [SDKTheme cellError];

    for (NSInteger i = 0; i < 81; i++) {
        if (i == sel) continue;
        BOOL peer = NO, same = NO;
        if (sel >= 0) {
            if (self.highlightPeers && [self.game isPeerRowOfIndex:sel andIndex:i]) peer = YES;
            if (self.highlightSameNumbers && selValue != 0 && [self.game valueAtIndex:i] == selValue) same = YES;
        }
        BOOL error = [self cellIsError:i];
        if (!peer && !same && !error) continue;
        CGRect cellRect = [self rectForCellAtIndex:i];
        if (peer) { [peerColor setFill]; CGContextFillRect(ctx, cellRect); }
        if (same) { [sameColor setFill]; CGContextFillRect(ctx, cellRect); }
        if (error) { [errorColor setFill]; CGContextFillRect(ctx, cellRect); }
    }

    if (sel >= 0) {
        [[SDKTheme cellSelect] setFill];
        CGContextFillRect(ctx, [self rectForCellAtIndex:sel]);
        if ([self cellIsError:sel]) {
            [[[SDKTheme danger] colorWithAlphaComponent:0.18] setFill];
            CGContextFillRect(ctx, [self rectForCellAtIndex:sel]);
        }
    }

    // ---- grid lines -------------------------------------------------------
    CGContextSetLineCap(ctx, kCGLineCapButt);
    UIColor *thin = [SDKTheme gridLine];
    UIColor *thick = [SDKTheme gridLineStrong];

    for (NSInteger i = 0; i <= 9; i++) {
        BOOL isBox = (i % 3 == 0);
        CGFloat width = isBox ? 1.7 : 0.75;
        CGContextSetStrokeColorWithColor(ctx, (isBox ? thick : thin).CGColor);
        CGContextSetLineWidth(ctx, width);

        CGFloat x = o.x + s * i;
        CGFloat y = o.y + s * i;
        // Vertical
        CGContextMoveToPoint(ctx, x, o.y);
        CGContextAddLineToPoint(ctx, x, o.y + s * 9.0);
        CGContextStrokePath(ctx);
        // Horizontal
        CGContextMoveToPoint(ctx, o.x, y);
        CGContextAddLineToPoint(ctx, o.x + s * 9.0, y);
        CGContextStrokePath(ctx);
    }

    // ---- digits -----------------------------------------------------------
    UIFont *givenFont = [SDKTheme roundedFont:s * 0.56 weight:UIFontWeightBold];
    UIFont *userFont = [SDKTheme roundedFont:s * 0.54 weight:UIFontWeightMedium];
    UIFont *noteFont = [SDKTheme roundedFont:s * 0.215 weight:UIFontWeightSemibold];

    UIColor *givenColor = [SDKTheme givenText];
    UIColor *userColor = [SDKTheme userText];
    UIColor *errorTextColor = [SDKTheme errorText];
    UIColor *noteColor = [SDKTheme noteText];

    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.alignment = NSTextAlignmentCenter;

    for (NSInteger i = 0; i < 81; i++) {
        CGRect cellRect = [self rectForCellAtIndex:i];
        NSInteger v = [self.game valueAtIndex:i];

        if (v > 0) {
            BOOL given = [self.game isGivenAtIndex:i];
            BOOL error = [self cellIsError:i];
            UIFont *font = given ? givenFont : userFont;
            UIColor *color = error ? errorTextColor : (given ? givenColor : userColor);
            NSDictionary *attrs = @{ NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: color,
                                     NSParagraphStyleAttributeName: para };
            NSString *str = [NSString stringWithFormat:@"%ld", (long)v];
            CGSize size = [str sizeWithAttributes:attrs];
            CGRect textRect = CGRectMake(CGRectGetMidX(cellRect) - size.width / 2.0,
                                         CGRectGetMidY(cellRect) - size.height / 2.0,
                                         size.width, size.height);
            [str drawInRect:textRect withAttributes:attrs];
        } else if ([self.game isEditableAtIndex:i]) {
            NSUInteger mask = [self.game noteMaskAtIndex:i];
            if (mask == 0) continue;
            NSDictionary *attrs = @{ NSFontAttributeName: noteFont,
                                     NSForegroundColorAttributeName: noteColor,
                                     NSParagraphStyleAttributeName: para };
            CGFloat third = s / 3.0;
            for (NSInteger d = 1; d <= 9; d++) {
                if ((mask & (1u << (NSUInteger)(d - 1))) == 0) continue;
                NSInteger nr = (d - 1) / 3, nc = (d - 1) % 3;
                CGRect mini = CGRectMake(CGRectGetMinX(cellRect) + nc * third,
                                         CGRectGetMinY(cellRect) + nr * third,
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
}

#pragma mark - Effects

- (void)flashIndex:(NSInteger)index color:(UIColor *)color {
    if (index < 0 || index > 80) return;
    CGRect cellRect = CGRectInset([self rectForCellAtIndex:index], 1.0, 1.0);
    CALayer *flash = [CALayer layer];
    flash.frame = cellRect;
    flash.cornerRadius = [self cellSize] * 0.18;
    flash.backgroundColor = [(color ?: [SDKTheme accent]) colorWithAlphaComponent:0.55].CGColor;
    flash.opacity = 0.0;
    [self.layer addSublayer:flash];

    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    anim.values = @[ @0.0, @0.85, @0.0 ];
    anim.keyTimes = @[ @0.0, @0.22, @1.0 ];
    anim.duration = 0.60;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [flash removeFromSuperlayer];
    }];
    [flash addAnimation:anim forKey:@"flash"];
    [CATransaction commit];
}

- (void)celebrateCompletion {
    NSArray<UIColor *> *palette = @[ [SDKTheme accent], [SDKTheme accentAlt], [SDKTheme success], [SDKTheme gold] ];
    for (NSInteger i = 0; i < 81; i++) {
        NSInteger row = i / 9, col = i % 9;
        NSTimeInterval delay = (row + col) * 0.035;
        UIColor *color = palette[(NSUInteger)((row + col) % (NSInteger)palette.count)];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self flashIndex:i color:color];
        });
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [touches.anyObject locationInView:self];
    _tracking = YES;
    NSInteger index = [self indexForPoint:p];
    if (index >= 0) {
        self.selectedIndex = index;
        [self.delegate boardView:self didSelectIndex:index];
    }
    if ([self.delegate respondsToSelector:@selector(boardView:didMoveFingerTo:insideBoard:)]) {
        [self.delegate boardView:self didMoveFingerTo:p insideBoard:(index >= 0)];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint p = [touches.anyObject locationInView:self];
    NSInteger index = [self indexForPoint:p];
    if (index >= 0 && index != _selectedIndex) {
        self.selectedIndex = index;
        [self.delegate boardView:self didSelectIndex:index];
        [SDKTheme selectionTick];
    }
    if ([self.delegate respondsToSelector:@selector(boardView:didMoveFingerTo:insideBoard:)]) {
        [self.delegate boardView:self didMoveFingerTo:p insideBoard:(index >= 0)];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _tracking = NO;
    if ([self.delegate respondsToSelector:@selector(boardViewDidEndTracking:)]) {
        [self.delegate boardViewDidEndTracking:self];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _tracking = NO;
    if ([self.delegate respondsToSelector:@selector(boardViewDidEndTracking:)]) {
        [self.delegate boardViewDidEndTracking:self];
    }
}

- (void)cancelTracking {
    _tracking = NO;
}

@end
