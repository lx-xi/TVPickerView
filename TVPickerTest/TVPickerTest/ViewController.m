//
//  ViewController.m
//  TVPickerTest
//
//  Created by xun.liu on 16/1/11.
//  Copyright © 2016年 TVM. All rights reserved.
//

#import "ViewController.h"
#import "TVPickerView.h"
#import "FBGlowLabel.h"


#define kScreenHeight   [UIScreen mainScreen].bounds.size.height
#define kScreenWidth    [UIScreen mainScreen].bounds.size.width

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)(((rgbValue) & 0xFF0000) >> 16))/255.0 green:((float)(((rgbValue) & 0xFF00) >> 8))/255.0 blue:((float)((rgbValue) & 0xFF))/255.0 alpha:1.0]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

@interface ViewController ()<TVPickerViewDataSource, TVPickerViewDelegate, TVPickerViewFocusDelegate>
{
    NSArray *_arr;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imgView.image = [UIImage imageNamed:@"home_bg"];
    [self.view addSubview:imgView];
    
    _arr = @[@"标清", @"高清", @"超清"];
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth-500)/2, 300, 500, 80*3)];
    [self.view addSubview:bgView];
    
    TVPickerView *picker = [[TVPickerView alloc] initWithFrame:bgView.bounds];
    picker.backgroundColor = [UIColor clearColor];
    picker.dataSource = self;
    picker.delegate = self;
    picker.focusDelegate = self;
    [picker reloadData];
    [bgView addSubview:picker];
}

//TVPickerViewDataSource
- (int)numberOfViewsInPickerView:(TVPickerView *)pickerView
{
    return (int)_arr.count;
}

- (UIView *)pickerView:(TVPickerView *)pickerView viewForIndex:(int)idx reusingView:(UIView *)view
{
    UIView *piView = view;
    if (!view) {
        piView = [[UIView alloc] init];
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        lab.center = CGPointMake(pickerView.bounds.size.height/2, pickerView.bounds.size.height/2);
        lab.font = [UIFont systemFontOfSize:48.0];
        lab.textAlignment = NSTextAlignmentCenter;
        lab.tag = 2016;
        
//        lab.transform = CGAffineTransformMakeRotation(-M_PI_2);
        [piView addSubview:lab];
    }
    
    FBGlowLabel *lab = [piView viewWithTag:2016];
    lab.text = _arr[idx];
    
    UIColor *color = [UIColor colorWithRed:(float)(1+arc4random()%99)/100 green:(float)(1+arc4random()%99)/100 blue:(float)(1+arc4random()%99)/100 alpha:1];
    piView.backgroundColor = color;
    
    return piView;
}

//TVPickerViewDelegate
- (void)pickerView:(TVPickerView *)pickerView didChangeToIndex:(int)index
{
    NSLog(@"didChangeToIndex = %d", index);
}

//TVPickerViewFocusDelegate
- (void)pickerView:(TVPickerView *)pickerView deepFocusStateChanged:(BOOL)isDeepFocus
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
