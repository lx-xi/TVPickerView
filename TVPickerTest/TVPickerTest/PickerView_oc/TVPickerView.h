//
//  TVPickerView.h
//  SUNTV_TV
//
//  Created by xun.liu on 16/1/7.
//  Copyright © 2016年 TVM. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TVPickerViewFocusDelegate;
@protocol TVPickerViewDelegate;
@protocol TVPickerViewDataSource;

@interface TVPickerView : UIView
{
    
}

@property (nonatomic, assign) id<TVPickerViewFocusDelegate>focusDelegate;
@property (nonatomic, assign) id<TVPickerViewDelegate>delegate;
@property (nonatomic, assign) id<TVPickerViewDataSource>dataSource;

@property (nonatomic, assign, readonly) BOOL deepFocus;
@property (nonatomic, assign, readonly) int selectedIndex;
@property (nonatomic, assign) BOOL isX;

- (void)reloadData;

//Iteration
- (void)iterate:(CGFloat)dx;
- (void)iterateForwards;
- (void)iterateBackwards;
- (void)scrollToIndex:(int)idx;

@end


@protocol TVPickerViewFocusDelegate <NSObject>

- (void)pickerView:(TVPickerView *)pickerView deepFocusStateChanged:(BOOL)isDeepFocus;

@end

@protocol TVPickerViewDelegate <NSObject>

- (void)pickerView:(TVPickerView *)pickerView didChangeToIndex:(int)index;

@end

@protocol TVPickerViewDataSource <NSObject>

- (int)numberOfViewsInPickerView:(TVPickerView *)pickerView;
- (UIView *)pickerView:(TVPickerView *)pickerView viewForIndex:(int)idx reusingView:(UIView *)view;

@end