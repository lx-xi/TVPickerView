//
//  TVPickerMover.h
//  SUNTV_TV
//
//  Created by xun.liu on 16/1/7.
//  Copyright © 2016年 TVM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^MoverBlock)(CGFloat call);

@interface TVPickerMover : NSObject

@property (nonatomic, strong) dispatch_block_t completed;
@property (nonatomic, strong) MoverBlock call;

- (void)startGeneratingWithTime:(NSTimeInterval)t totalDistance:(CGFloat)dx moverBlock:(MoverBlock)call completed:(dispatch_block_t)completed;

- (void)stopGenerating;

- (void)timerFired;

@end
