//
//  TVPickerMover.m
//  SUNTV_TV
//
//  Created by xun.liu on 16/1/7.
//  Copyright © 2016年 TVM. All rights reserved.
//

#import "TVPickerMover.h"

@interface TVPickerMover ()
{
    NSTimer *_timer;
    CGFloat _stepDistance;
    int _steps;
    int _count;
}

@end

@implementation TVPickerMover

- (id)init
{
    self = [super init];
    if (self) {
        _stepDistance = 0.0;
        _steps = 25;
        _count = 0;
    }
    
    return self;
}

- (void)startGeneratingWithTime:(NSTimeInterval)t totalDistance:(CGFloat)dx moverBlock:(MoverBlock)call completed:(dispatch_block_t)completed
{
    [self stopGenerating];
    
    self.call = call;
    _stepDistance = dx / (CGFloat)_steps;
    _count = 0;
    self.completed = completed;
    double time = t / (double)_steps;
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
}


- (void)stopGenerating
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)timerFired
{
    if (_call) {
        _call(_stepDistance);
    }
    
    _count = _count + 1;
    
    if (_count >= _steps) {
        [self stopGenerating];
        _completed();
    }
}

@end
