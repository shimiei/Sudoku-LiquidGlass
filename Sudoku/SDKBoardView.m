//
//  SDKBoardView.m
//  Sudoku — Apple HIG rebuild
//

#import "SDKBoardView.h"
#import "SDKTheme.h"
#import <QuartzCore/QuartzCore.h>

@interface SDKBoardView ()
@property (nonatomic, strong) CAShapeLayer *selectionRing;
@property (nonatomic) NSInteger flashIndex;
@property (nonatomic, strong, nullable) UIColor *flashColor;
@end

@implementation SDKBoardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self commonInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self commonInit];
    return self;
}

- (void)commonInit {
    _contentInset = 6.0;
    _selectedIndex = -1;
    _flashIndex = -1;
    _highlightPeers = YES;
    _highlightSameNumbers = YES;
    _showConflicts = YES;

    self.backgroundColor = [SDKTheme boardBackground];
    self.layer.cornerRadius = 10.0;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    self.layer.borderColor = [SDKTheme cgColor:[SDKTheme gridLine] traits:self.traitCollection];

    self.isAccessibilityElement = YES;
    self.accessibilityLabel = @"数独棋盘";

    _selectionRing = [CAShapeLayer layer];
    _selectionRing.fillColor = UIColor.clearColor.CGColor;
    _selectionRing.strokeColor = [SDKTheme cgColor:[SDKTheme userColor] traits:self.traitCollection];
    _selectionRing.lineWidth = 2.0;
    _selectionRing.opacity = 0.0;
    [self.layer addSublayer:_selectionRing];
}

#pragma mark - Geometry

- (CGFloat)cellSize {
    return MAX(1.0, CGRectGetWidth([self gridRect]) / 9.0);
}

- (CGRect)gridRect {
    CGFloat side = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) - self.contentInset * 2.0;
    side = MAX(side, 9.0);
    return CGRectMake((CGRectGetWidth(self.bounds) - side) / 2.0,
                      (CGRectGetHeight(self.bounds) - side) / 2.0, side, side);
}

- (CGRect)rectForIndex:(NSInteger)index {
    if (index < 0 || index > 80) return CGRectZero;
    CGFloat cell = [self cellSize];
    CGRect grid = [self gridRect];
    return CGRectMake(CGRectGetMinX(grid) + (index % 9) * cell,
                      CGRectGetMinY(grid) + (index / 9) * cell, cell, cell);
}

- (CGPoint)centerForIndex:(NSInteger)index {
    CGRect r = [self rectForIndex:index];
    return CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
}

- (NSInteger)indexAtPoint:(CGPoint)point {
    CGRect grid = [self gridRect];
    if (!CGRectContainsPoint(CGRectInset(grid, -2.0, -2.0), point)) return -1;
    CGFloat cell = [self cellSize];
    NSInteger col = (NSInteger)((point.x - CGRectGetMinX(grid)) / cell);
    NSInteger row = (NSInteger)((point.y - CGRectGetMinY(grid)) / cell);
    return MAX(0, MIN(8, row)) * 9 + MAX(0, MIN(8, col));
}

#pragma mark - Data

- (void)setGame:(SDKGameState *)game {
    _game = game;
    [self reloadData];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (selectedIndex < 0 || selectedIndex > 80) selectedIndex = -1;
    if (_selectedIndex == selectedIndex) return;
    _selectedIndex = selectedIndex;
    [self updateSelectionRing];
    [self setNeedsDisplay];
}

- (void)setHighlightPeers:(BOOL)on { _highlightPeers = on; [self setNeedsDisplay]; }
- (void)setHighlightSameNumbers:(BOOL)on { _highlightSameNumbers = on; [self setNeedsDisplay]; }
- (void)setShowConflicts:(BOOL)on { _showConflicts = on; [self setNeedsDisplay]; }
- (void)setAutoCheck:(BOOL)on { _autoCheck = on; [self setNeedsDisplay]; }

- (void)reloadData {
    [self setNeedsDisplay];
    [self updateSelectionRing];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self updateSelectionRing];
    [CATransaction commit];
}

- (void)updateSelectionRing {
    if (_selectedIndex < 0) {
        _selectionRing.opacity = 0.0;
        return;
    }
    CGRect rect = CGRectInset([self rectForIndex:_selectedIndex], 1.5, 1.5);
    if (CGRectGetWidth(rect) <= 0) {
        _selectionRing.opacity = 0.0;
        return;
    }
    _selectionRing.path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3.0].CGPath;
    _selectionRing.strokeColor = [SDKTheme cgColor:[SDKTheme userColor] traits:self.traitCollection];
    _selectionRing.opacity = 1.0;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if (![self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) return;
    }
    self.layer.borderColor = [SDKTheme cgColor:[SDKTheme gridLine] traits:self.traitCollection];
    [self updateSelectionRing];
    [self setNeedsDisplay];
}

#pragma mark - Flash / celebrate

- (void)flashIndex:(NSInteger)index color:(UIColor *)color {
    self.flashIndex = index;
    self.flashColor = color;
    [self setNeedsDisplay];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        // Only clear the flash this timer started, never a newer one.
        if (weakSelf.flashIndex != index) return;
        weakSelf.flashIndex = -1;
        weakSelf.flashColor = nil;
        [weakSelf setNeedsDisplay];
    });
}

- (void)celebrateCompletion {
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = CGAffineTransformMakeScale(1.015, 1.015);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    [self drawGridInRect:[self gridRect] context:ctx];
}

- (void)drawGridInRect:(CGRect)grid context:(CGContextRef)ctx {
    if (!ctx || CGRectGetWidth(grid) < 9.0) return;

    UITraitCollection *traits = self.traitCollection;
    SDKGameState *game = self.game;
    CGFloat cell = CGRectGetWidth(grid) / 9.0;
    CGFloat hairline = 1.0 / UIScreen.mainScreen.scale;

    NSInteger selRow = -1, selCol = -1, selValue = 0;
    if (self.selectedIndex >= 0 && game) {
        selRow = self.selectedIndex / 9;
        selCol = self.selectedIndex % 9;
        selValue = [game valueAtIndex:self.selectedIndex];
    }

    // 1 — cell backgrounds
    if (game) {
        for (NSInteger i = 0; i < 81; i++) {
            NSInteger row = i / 9, col = i % 9;
            NSInteger value = [game valueAtIndex:i];
            UIColor *fill = nil;

            if (self.selectedIndex >= 0) {
                if (i == self.selectedIndex) {
                    fill = [SDKTheme selectFill];
                } else if (self.highlightPeers &&
                           (row == selRow || col == selCol ||
                            (row / 3 == selRow / 3 && col / 3 == selCol / 3))) {
                    fill = [SDKTheme peerFill];
                }
                if (!fill && self.highlightSameNumbers && selValue > 0 && value == selValue) {
                    fill = [SDKTheme sameFill];
                }
            }

            if (i == self.flashIndex && self.flashColor) {
                fill = self.flashColor;
            } else if (value > 0 && ![game isGivenAtIndex:i]) {
                if ((self.autoCheck && [game isWrongAtIndex:i]) ||
                    (self.showConflicts && [game hasConflictAtIndex:i])) {
                    fill = [SDKTheme errorFill];
                }
            }

            if (fill) {
                CGContextSetFillColorWithColor(ctx, [SDKTheme cgColor:fill traits:traits]);
                CGContextFillRect(ctx, CGRectMake(CGRectGetMinX(grid) + col * cell,
                                                  CGRectGetMinY(grid) + row * cell, cell, cell));
            }
        }
    }

    // 2 — hairline rules
    CGContextSetLineWidth(ctx, hairline);
    CGContextSetStrokeColorWithColor(ctx, [SDKTheme cgColor:[SDKTheme gridLine] traits:traits]);
    for (NSInteger i = 1; i < 9; i++) {
        if (i % 3 == 0) continue;
        CGFloat x = CGRectGetMinX(grid) + i * cell;
        CGFloat y = CGRectGetMinY(grid) + i * cell;
        CGContextMoveToPoint(ctx, x, CGRectGetMinY(grid));
        CGContextAddLineToPoint(ctx, x, CGRectGetMaxY(grid));
        CGContextMoveToPoint(ctx, CGRectGetMinX(grid), y);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(grid), y);
    }
    CGContextStrokePath(ctx);

    // 3 — box rules and outer border
    CGContextSetLineWidth(ctx, MAX(1.0, cell * 0.045));
    CGContextSetStrokeColorWithColor(ctx, [SDKTheme cgColor:[SDKTheme boxLine] traits:traits]);
    for (NSInteger i = 3; i < 9; i += 3) {
        CGFloat x = CGRectGetMinX(grid) + i * cell;
        CGFloat y = CGRectGetMinY(grid) + i * cell;
        CGContextMoveToPoint(ctx, x, CGRectGetMinY(grid));
        CGContextAddLineToPoint(ctx, x, CGRectGetMaxY(grid));
        CGContextMoveToPoint(ctx, CGRectGetMinX(grid), y);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(grid), y);
    }
    CGContextStrokePath(ctx);
    CGContextStrokeRect(ctx, CGRectInset(grid, cell * 0.015, cell * 0.015));

    if (!game) return;

    // 4 — digits and pencil notes
    UIFont *valueFont = [SDKTheme digitsFontOfSize:cell * 0.58 weight:UIFontWeightSemibold];
    UIFont *noteFont = [SDKTheme digitsFontOfSize:cell * 0.22 weight:UIFontWeightRegular];
    NSMutableParagraphStyle *center = [NSMutableParagraphStyle new];
    center.alignment = NSTextAlignmentCenter;

    for (NSInteger i = 0; i < 81; i++) {
        CGRect r = CGRectMake(CGRectGetMinX(grid) + (i % 9) * cell,
                              CGRectGetMinY(grid) + (i / 9) * cell, cell, cell);
        NSInteger value = [game valueAtIndex:i];

        if (value > 0) {
            BOOL isGiven = [game isGivenAtIndex:i];
            BOOL wrong = NO;
            if (!isGiven) {
                if (self.autoCheck && [game isWrongAtIndex:i]) wrong = YES;
                else if (self.showConflicts && [game hasConflictAtIndex:i]) wrong = YES;
            }
            UIColor *color = isGiven ? [SDKTheme givenColor]
                                     : (wrong ? [SDKTheme errorColor] : [SDKTheme userColor]);
            NSString *text = [NSString stringWithFormat:@"%ld", (long)value];
            NSDictionary *attrs = @{ NSFontAttributeName : valueFont,
                                     NSForegroundColorAttributeName : color,
                                     NSParagraphStyleAttributeName : center };
            CGSize size = [text sizeWithAttributes:attrs];
            [text drawInRect:CGRectMake(CGRectGetMidX(r) - size.width / 2.0,
                                        CGRectGetMidY(r) - size.height / 2.0,
                                        size.width, size.height)
              withAttributes:attrs];
            continue;
        }

        unsigned mask = [game noteMaskAtIndex:i];
        if (!mask) continue;
        NSDictionary *attrs = @{ NSFontAttributeName : noteFont,
                                 NSForegroundColorAttributeName : [SDKTheme noteColor],
                                 NSParagraphStyleAttributeName : center };
        CGFloat sub = cell / 3.0;
        for (NSInteger d = 1; d <= 9; d++) {
            if (!(mask & (1u << (NSUInteger)(d - 1)))) continue;
            CGRect noteRect = CGRectMake(CGRectGetMinX(r) + ((d - 1) % 3) * sub,
                                         CGRectGetMinY(r) + ((d - 1) / 3) * sub, sub, sub);
            NSString *text = [NSString stringWithFormat:@"%ld", (long)d];
            CGSize size = [text sizeWithAttributes:attrs];
            [text drawInRect:CGRectMake(CGRectGetMidX(noteRect) - size.width / 2.0,
                                        CGRectGetMidY(noteRect) - size.height / 2.0,
                                        size.width, size.height)
              withAttributes:attrs];
        }
    }
}

#pragma mark - Touches

- (void)reportTrackingWithPoint:(CGPoint)point index:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(boardView:didMoveFingerTo:cellIndex:insideBoard:)]) {
        [self.delegate boardView:self didMoveFingerTo:point cellIndex:index
                     insideBoard:CGRectContainsPoint(self.bounds, point)];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (!touch) return;
    CGPoint point = [touch locationInView:self];
    NSInteger index = [self indexAtPoint:point];
    if (index >= 0) {
        self.selectedIndex = index;
        [SDKTheme selection];
        if ([self.delegate respondsToSelector:@selector(boardView:didSelectIndex:)]) {
            [self.delegate boardView:self didSelectIndex:index];
        }
    }
    [self reportTrackingWithPoint:point index:index];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = touches.anyObject;
    if (!touch) return;
    CGPoint point = [touch locationInView:self];
    NSInteger index = [self indexAtPoint:point];
    if (index >= 0 && index != self.selectedIndex) self.selectedIndex = index;
    [self reportTrackingWithPoint:point index:index];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(boardViewDidEndTracking:)]) {
        [self.delegate boardViewDidEndTracking:self];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self.delegate respondsToSelector:@selector(boardViewDidEndTracking:)]) {
        [self.delegate boardViewDidEndTracking:self];
    }
}

#pragma mark - Accessibility

- (NSString *)accessibilityValue {
    if (!self.game || self.selectedIndex < 0) return @"";
    NSInteger value = [self.game valueAtIndex:self.selectedIndex];
    NSInteger row = self.selectedIndex / 9 + 1;
    NSInteger col = self.selectedIndex % 9 + 1;
    if (value > 0) {
        return [NSString stringWithFormat:@"第 %ld 行第 %ld 列，数字 %ld", (long)row, (long)col, (long)value];
    }
    return [NSString stringWithFormat:@"第 %ld 行第 %ld 列，空", (long)row, (long)col];
}

@end
