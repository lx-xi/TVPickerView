//
//  TVPickerView.m
//  SUNTV_TV
//
//  Created by xun.liu on 16/1/7.
//  Copyright © 2016年 TVM. All rights reserved.
//

#import "TVPickerView.h"
#import "TVPickerMover.h"

@interface UIView (TVPickerViewExtensions)

- (UIView *)setupForPicker:(TVPickerView *)picker;
- (void)setX:(CGFloat)x dx:(CGFloat)dx;
- (void)setY:(CGFloat)y dy:(CGFloat)dy;
- (void)sizeToView:(UIView *)v;

@end

@implementation UIView (TVPickerViewExtensions)

- (UIView *)setupForPicker:(TVPickerView *)picker
{
    self.translatesAutoresizingMaskIntoConstraints = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    CGSize size = CGSizeMake(CGRectGetWidth(picker.bounds)/2.0, CGRectGetHeight(picker.bounds));
    self.frame = CGRectMake(0, 0, size.width, size.height);
//    self.transform = CGAffineTransformMakeRotation(M_PI_2);
    return self;
}

- (void)setX:(CGFloat)x dx:(CGFloat)dx
{
    CGPoint point = self.center;
    point.x = x;
    self.center = point;
    
    float scaleAmount = (1 - MAX(dx, 0.65)) + 0.65;
    self.layer.transform = CATransform3DMakeScale(1.0 * scaleAmount, 1.0 * scaleAmount, 1.0);
}

- (void)setY:(CGFloat)y dy:(CGFloat)dy
{
    CGPoint point = self.center;
    point.y = y;
    self.center = point;
    
    float scaleAmount = (1 - MAX(dy, 0.65)) + 0.65;
    self.layer.transform = CATransform3DMakeScale(1.0 * scaleAmount, 1.0 * scaleAmount, 1.0);
}

- (void)sizeToView:(UIView *)v
{
    self.frame = v.bounds;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

@end


@interface TVPickerView ()
{
    NSTimeInterval _animationInterval;
    CGFloat _swipeMultiplier;
    int _maxDrawn;
    
    UIView *_contentView;
    
    int _itemCount;
    NSMutableDictionary *_indexesAndViews;
    
    TVPickerMover *_mover;
}

@property (nonatomic, assign) int currentIndex;

@end

@implementation TVPickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _isX = YES;
        _animationInterval = 0.1;
        _swipeMultiplier = 0.5;
        _maxDrawn = 4;
        _mover = [[TVPickerMover alloc] init];
        _contentView = [[UIView alloc] init];
        _deepFocus = NO;
        _currentIndex = 0;
        
        [self setup];
        
        _itemCount = 0;
        _indexesAndViews = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)setDeepFocus:(BOOL)deepFocus
{
    _deepFocus = deepFocus;
    
    [UIView animateWithDuration:_animationInterval animations:^{
        if (_deepFocus) {
            [self bringIntoDeepFocus];
        }
        else {
            [self bringOutOfDeepFocus];
        }
    }];
    
    if (_deepFocus) {
        [self becomeFirstResponder];
    }
    else {
        [self resignFirstResponder];
    }
}

- (void)setCurrentIndex:(int)currentIndex
{
    if (_currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        if (_delegate && [_delegate respondsToSelector:@selector(pickerView:didChangeToIndex:)]) {
            [_delegate pickerView:self didChangeToIndex:currentIndex];
        }
    }
}

- (int)selectedIndex
{
    return _currentIndex;
}

- (void)reloadData
{
    if (!_dataSource) {
        return;
    }
    
    self.layoutMargins = UIEdgeInsetsZero;
    
    _itemCount = [_dataSource numberOfViewsInPickerView:self];
    [self loadFromIndex:0];
    
    if (_currentIndex < _itemCount - 1) {
        [self scrollToIndex:_currentIndex animated:NO];
    }
    else {
        [self scrollToIndex:0 animated:NO];
    }
}

- (void)loadFromIndex:(int)index
{
    if (!_dataSource) {
        return;
    }
    
    NSArray *allViews = [_indexesAndViews allValues];
    for (UIView *v in allViews) {
        [v removeFromSuperview];
    }
    [_indexesAndViews removeAllObjects];
    
    int nIndex = index + 1;
    
    if (nIndex == _itemCount) {
        nIndex = _itemCount - 1;
    }
    
    if (nIndex >= (_itemCount - _maxDrawn)) {
        nIndex = nIndex - _maxDrawn;
    }
    
    if (nIndex < 0) {
        nIndex = 0;
    }
    
    NSLog(@"%d", MIN(_maxDrawn + nIndex, _itemCount));
    for (int idx; idx < MIN(_maxDrawn + nIndex, _itemCount); idx++) {
        UIView *v = [_dataSource pickerView:self viewForIndex:idx reusingView:nil];
//        v.transform = CGAffineTransformMakeRotation(M_PI_2);
        [_contentView addSubview:[v setupForPicker:self]];
        
        [_indexesAndViews setObject:v forKey:[NSString stringWithFormat:@"%d", idx]];
        
        if (_isX) {
            [v setX:[self xPositionForIndex:idx] dx:1];
        }
        else {
            [v setY:[self yPositionForIndex:idx] dy:1];
        }
    }
    
    
    if (_isX) {
        [self iterate:0];
    }
    else {
        [self iterateY:0];
    }
    [self scrollToNearestIndex:0.0 uncancellable:NO];
    
    //Waiting fixes everything
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_isX) {
            [self internalScrollToIndex:index animated:YES multiplier:2.0 speed:0.1];
        }
        else {
            [self Y_internalScrollToIndex:index animated:YES multiplier:2.0 speed:0.1];
        }
    });
}

- (void)setup
{
    _contentView.frame = self.bounds;
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.clipsToBounds = YES;
    _contentView.layer.cornerRadius = 7.0;
    [self addSubview:_contentView];
    
    self.backgroundColor = [UIColor clearColor];

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 10);
    self.layer.cornerRadius = 7.0;
    
    [self bringOutOfFocus];
}


#pragma mark Focus Control
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    if (self == context.nextFocusedView) {
        [coordinator addCoordinatedAnimations:^{
            // focusing animations
            [UIView animateWithDuration:_animationInterval animations:^{
                [self bringIntoFocus];
            }];
            
        } completion:^{
            // completion
        }];
    } else if (self == context.previouslyFocusedView) {
        [coordinator addCoordinatedAnimations:^{
            // unfocusing animations
            [UIView animateWithDuration:_animationInterval animations:^{
                [self bringOutOfFocus];
            }];
            
        } completion:^{
            // completion
        }];
    }
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
    return !_deepFocus;
}

- (void)bringIntoFocus
{
    self.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0);
//    self.layer.shadowRadius = 7.0;
//    self.layer.shadowOpacity = 0.2;
////    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.backgroundColor = [UIColor clearColor];
//    _contentView.alpha = 0.7;
}

- (void)bringOutOfFocus
{
    self.layer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0);
//    self.layer.shadowRadius = 0.0;
//    self.layer.shadowOpacity = 0.0;
    _contentView.backgroundColor = [UIColor clearColor];
}

- (void)bringIntoDeepFocus
{
    self.layer.transform = CATransform3DMakeScale(1.4, 1.4, 1.0);
//    self.layer.shadowRadius = 15.0;
//    self.layer.shadowOpacity = 0.7;
////    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.backgroundColor = [UIColor clearColor];
    
    if (_focusDelegate && [_focusDelegate respondsToSelector:@selector(pickerView:deepFocusStateChanged:)]) {
        [_focusDelegate pickerView:self deepFocusStateChanged:YES];
    }
}

- (void)bringOutOfDeepFocus
{
    [self bringIntoFocus];
    if (_focusDelegate && [_focusDelegate respondsToSelector:@selector(pickerView:deepFocusStateChanged:)]) {
        [_focusDelegate pickerView:self deepFocusStateChanged:NO];
    }
}

- (BOOL)canBecomeFocused
{
    return YES;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark Touch Control
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (!_deepFocus) {
        return;
    }
    
    [_mover stopGenerating];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (!_deepFocus) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    CGPoint lastLocation = [touch previousLocationInView:self];
    CGPoint thisLocation = [touch locationInView:self];
    
    if (_isX) {
        //to x
        CGFloat dx = thisLocation.x - lastLocation.x;
        [self iterate:dx];
    }
    else {
        //to y
        CGFloat dy = thisLocation.y - lastLocation.y;
        [self iterateY:dy];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (!_deepFocus) {
        return;
    }
    
    [self scrollToNearestIndex:0.3 uncancellable:NO];
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event
{
    [super pressesBegan:presses withEvent:event];
    UIPress *press = [presses anyObject];
//    if (!press) {
//        return;
//    }
    
    if (press.type == UIPressTypeSelect) {
        BOOL changedValue = !_deepFocus;
        
        if (!changedValue) {
            [self scrollToNearestIndex:0.3 uncancellable:YES];
        }
        
        _deepFocus = changedValue;
    }
    
    if (!_deepFocus) {
        return;
    }
    
    if (press.type == UIPressTypeUpArrow || press.type == UIPressTypeRightArrow) {
        [self iterateForwards];
    }
    else if (press.type == UIPressTypeDownArrow || press.type == UIPressTypeLeftArrow) {
        [self iterateBackwards];
    }
}

#pragma mark Iteration
//to x
- (void)iterate:(CGFloat)dx
{
    NSArray *views = [_indexesAndViews allValues];
    for (UIView *v in views) {
        CGFloat newViewX = dx * _swipeMultiplier + v.center.x;
        
        CGPoint containerCenter = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        CGFloat vdx = MIN(fabs(containerCenter.x - newViewX) / containerCenter.x, 1.0);
        
        [v setX:newViewX dx:vdx];
    }
    
    [self calculate];
}
//to y
- (void)iterateY:(CGFloat)dy
{
    NSArray *views = [_indexesAndViews allValues];
    for (UIView *v in views) {
        CGFloat newViewY = dy * _swipeMultiplier + v.center.y;
        
        CGPoint containerCenter = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        CGFloat vdy = MIN(fabs(containerCenter.y - newViewY) / containerCenter.y, 1.0);
        
        [v setY:newViewY dy:vdy];
    }
    
    [self calculate];
}

- (void)iterateForwards
{
    if (_currentIndex >= (_itemCount - 1)) {
        return;
    }
    
    if (_isX) {
        [self internalScrollToIndex:_currentIndex+1 animated:YES multiplier:1.0 speed:0.1];
    }
    else {
        [self Y_internalScrollToIndex:_currentIndex+1 animated:YES multiplier:1.0 speed:0.1];
    }
}

- (void)iterateBackwards
{
    if (_currentIndex == 0) {
        return;
    }
    
    if (_isX) {
        [self internalScrollToIndex:_currentIndex-1 animated:YES multiplier:1.0 speed:0.1];
    }
    else {
        [self Y_internalScrollToIndex:_currentIndex-1 animated:YES multiplier:1.0 speed:0.1];
    }
}

- (void)scrollToNearestIndex:(NSTimeInterval)speed uncancellable:(BOOL)uncancellable
{
    //to x
    int locatedIndex = [self nearestViewToCenter_index];
    CGFloat offset = [self nearestViewToCenter_offset];
    if (!_isX) {
        //to y
        locatedIndex = [self nearestViewToCenter_index_Y];
        offset = [self nearestViewToCenter_offset_Y];
    }
    
    if (uncancellable) {
        self.currentIndex = locatedIndex;
    }
    
    [_mover startGeneratingWithTime:speed totalDistance:offset * 2.0 moverBlock:^(CGFloat call) {
        if (_isX) {
            [self iterate:call];
        }
        else {
            [self iterateY:call];
        }
        
    } completed:^{
        //Don't want to tell the delegate until now because the user could cancel the animation
        self.currentIndex = locatedIndex;
    }];
}

//to x
- (int)nearestViewToCenter_index
{
    CGFloat targetX = self.bounds.size.width / 2.0;
    int locatedIndex = 0;
    CGFloat smallestDistance = CGFLOAT_MAX;
    CGFloat offset = 0.0;
    
    NSArray *keys = [_indexesAndViews allKeys];
    for (NSString *idxStr in keys) {
        UIView *view = [_indexesAndViews objectForKey:idxStr];
        
        CGFloat x = view.center.x;
        
        CGFloat dx = fabs(targetX - x);
        
        if (dx < smallestDistance) {
            locatedIndex = [idxStr intValue];
            smallestDistance = dx;
            offset = targetX - x;
        }
        
        if (smallestDistance < view.frame.size.width/2.0) {
            //No need to continue searching at this point
            break;
        }
    }
    
    return locatedIndex;
}
//to y
- (int)nearestViewToCenter_index_Y
{
    CGFloat targetY = self.bounds.size.height / 2.0;
    int locatedIndex = 0;
    CGFloat smallestDistance = CGFLOAT_MAX;
    CGFloat offset = 0.0;
    
    NSArray *keys = [_indexesAndViews allKeys];
    for (NSString *idxStr in keys) {
        UIView *view = [_indexesAndViews objectForKey:idxStr];
        
        CGFloat y = view.center.y;
        
        CGFloat dy = fabs(targetY - y);
        
        if (dy < smallestDistance) {
            locatedIndex = [idxStr intValue];
            smallestDistance = dy;
            offset = targetY - y;
        }
        
        if (smallestDistance < view.frame.size.height/2.0) {
            //No need to continue searching at this point
            break;
        }
    }
    
    return locatedIndex;
}

//to x
- (CGFloat)nearestViewToCenter_offset
{
    CGFloat targetX = self.bounds.size.width / 2.0;
    int locatedIndex = 0;
    CGFloat smallestDistance = FLT_MAX;
    CGFloat offset = 0.0;
    
    NSArray *keys = [_indexesAndViews allKeys];
    for (NSString *idxStr in keys) {
        UIView *view = [_indexesAndViews objectForKey:idxStr];
        
        CGFloat x = view.center.x;
        
        CGFloat dx = fabs(targetX - x);
        
        if (dx < smallestDistance) {
            locatedIndex = [idxStr intValue];
            smallestDistance = dx;
            offset = targetX - x;
        }
        
        if (smallestDistance < view.frame.size.width/2.0) {
            //No need to continue searching at this point
            break;
        }
    }
    
    return offset;
}

//to y
- (CGFloat)nearestViewToCenter_offset_Y
{
    CGFloat targetY = self.bounds.size.height / 2.0;
    int locatedIndex = 0;
    CGFloat smallestDistance = CGFLOAT_MAX;
    CGFloat offset = 0.0;
    
    NSArray *keys = [_indexesAndViews allKeys];
    for (NSString *idxStr in keys) {
        UIView *view = [_indexesAndViews objectForKey:idxStr];
        
        CGFloat y = view.center.y;
        
        CGFloat dy = fabs(targetY - y);
        
        if (dy < smallestDistance) {
            locatedIndex = [idxStr intValue];
            smallestDistance = dy;
            offset = targetY - y;
        }
        
        if (smallestDistance < view.frame.size.height/2.0) {
            //No need to continue searching at this point
            break;
        }
    }
    
    return offset;
}

- (void)scrollToIndex:(int)idx
{
    [self scrollToIndex:idx animated:YES];
}

//TODO: animated doesn't work. Fix it and make it public
- (void)scrollToIndex:(int)idx animated:(BOOL)animated
{
    int di = abs(idx - _currentIndex);
    BOOL a = animated;
    
    if (di > 5) {
        a = NO;
    }
    
    if (_isX) {
        [self internalScrollToIndex:idx animated:a multiplier:2.0 speed:0.2];
    }
    else {
        [self Y_internalScrollToIndex:idx animated:a multiplier:2.0 speed:0.2];
    }
}

//to x
- (void)internalScrollToIndex:(int)idx animated:(BOOL)animated multiplier:(CGFloat)multiplier speed:(NSTimeInterval)speed
{
    if (!animated) {
        [self loadFromIndex:idx];
        return;
    }
    
    CGFloat x = [self xPositionForIndex:idx];
    CGFloat distance = [self xPositionForIndex:_currentIndex] - x;
    CGFloat s = animated ? speed : 0.0;
    
    [_mover startGeneratingWithTime:s totalDistance:distance * multiplier moverBlock:^(CGFloat call) {
        [self iterate:call];
    } completed:^{
        [self scrollToNearestIndex:s uncancellable:NO];
    }];
}

//to y
- (void)Y_internalScrollToIndex:(int)idx animated:(BOOL)animated multiplier:(CGFloat)multiplier speed:(NSTimeInterval)speed
{
    if (!animated) {
        [self loadFromIndex:idx];
        return;
    }
    
    CGFloat y = [self yPositionForIndex:idx];
    CGFloat distance = [self yPositionForIndex:_currentIndex] - y;
    CGFloat s = animated ? speed : 0.0;
    
    [_mover startGeneratingWithTime:s totalDistance:distance * multiplier moverBlock:^(CGFloat call) {
        [self iterateY:call];
    } completed:^{
        [self scrollToNearestIndex:s uncancellable:NO];
    }];
}

//to x
- (CGFloat)xPositionForIndex:(int)idx
{
    return (((CGFloat)idx * self.frame.size.width) / (CGFloat)2.0) + self.frame.size.width / 2.0;
}

//to y
- (CGFloat)yPositionForIndex:(int)idx
{
    return (((CGFloat)idx * self.frame.size.height) / (CGFloat)2.0) + self.frame.size.height / 2.0;
}

#pragma mark Lazy
- (void)calculate
{
    if (!_dataSource) {
        return;
    }
    
    
    NSArray *indexesDrawn = [_indexesAndViews allKeys];  //字符串数组
    [indexesDrawn sortedArrayUsingSelector:@selector(compare:)];
    
    if (indexesDrawn.count < _maxDrawn) {
        //No laziness here!
        return;
    }
    
    int locatedIndex = [self nearestViewToCenter_index];
    
    if (locatedIndex == 0 || locatedIndex == (_itemCount - 1)) {
        //TODO: maybe add looping? Nah.
        return;
    }
    
    NSInteger n = [indexesDrawn indexOfObject:[NSString stringWithFormat:@"%d", locatedIndex]];
    
    //Add / Reuse a view if required
    int newIdx;
    int reuseIndex = 0;
    CGFloat position = 0.0;
    
    UIView *locatedView = [_indexesAndViews objectForKey:[NSString stringWithFormat:@"%d", locatedIndex]];
    
    if (n == 0) {
        newIdx = locatedIndex - 1;
        reuseIndex = [indexesDrawn[_maxDrawn-1] intValue];
        if (_isX) {
            position = locatedView.center.x - locatedView.bounds.size.width;
        }
        else {
            position = locatedView.center.y - locatedView.bounds.size.height;
        }
    }
    else if (n == _maxDrawn - 1) {
        newIdx = locatedIndex + 1;
        reuseIndex = [indexesDrawn[0] intValue];
        if (_isX) {
            position = locatedView.center.x + locatedView.bounds.size.width;
        }
        else {
            position = locatedView.center.y + locatedView.bounds.size.height;
        }
    }

    int newIndex = newIdx;
    
    UIView *reusingView = [_indexesAndViews objectForKey:[NSString stringWithFormat:@"%d", reuseIndex]];
    [_indexesAndViews removeObjectForKey:[NSString stringWithFormat:@"%d", reuseIndex]];
    
    UIView *newView = [_dataSource pickerView:self viewForIndex:newIndex reusingView:reusingView];
    [_indexesAndViews setObject:newView forKey:[NSString stringWithFormat:@"%d", newIndex]];
    
    if (newView != reusingView) {   //newView !== reusingView
        if (reusingView) {
            [reusingView removeFromSuperview];
        }
//        newView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [_contentView addSubview:[newView setupForPicker:self]];
    }
    
    if (_isX) {
        [newView setX:position dx:1.0];
    }
    else {
        [newView setY:position dy:1.0];
    }
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
