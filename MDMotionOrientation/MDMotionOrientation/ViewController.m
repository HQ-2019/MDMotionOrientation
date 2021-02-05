//
//  ViewController.m
//  MDMotionOrientation
//
//  Created by hq on 2021/2/4.
//

#import "ViewController.h"

#import "MDMotionOrientationUtil.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *motionAcceleration;                       /**<  加速计输出参数  */
@property (weak, nonatomic) IBOutlet UILabel *xxxxLabel;                                /**<  系统方向改变时，计算加速计参数  */

@property (weak, nonatomic) IBOutlet UILabel *motionDeviceOrientationLabel;             /**<  通过加速计计算的设备方向  */
@property (weak, nonatomic) IBOutlet UILabel *systemDeviceOrientationLabel;             /**<  通过系统读取的设备方向  */

@property (weak, nonatomic) IBOutlet UILabel *motionInterfaceOrientationLabel;          /**<  通过加速计计算的界面方向  */
@property (weak, nonatomic) IBOutlet UILabel *systemInterfaceOrientationLabel;          /**<  通过系统读取的界面方向  */

@property (nonatomic, strong) MDMotionOrientationUtil *motionOrientationUtil;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self deviceOrientationChanged:nil];
    [self interfaceOrientationChanged:nil];
    
    // 注册监听获取设备方向的变化
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationChanged:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    // 启动加速度更新
    [self.motionOrientationUtil startAccelerometerUpdates:^(UIDeviceOrientation deviceOrientation, UIInterfaceOrientation interfaceOrientation, CMAccelerometerData * _Nullable accelerometerData) {
        CMAcceleration acceleration = accelerometerData.acceleration;
        float xx = -acceleration.x;
        float yy = acceleration.y;
        float zz = acceleration.z;
        float angle = atan2(yy, xx);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.motionAcceleration.text = [NSString stringWithFormat:@"x:%.3f  y:%.3f  z:%.3f  angle:%.3f", xx, yy, zz, angle];
            self.motionDeviceOrientationLabel.text = [self stringForDeviceOrientation:deviceOrientation];
            self.motionInterfaceOrientationLabel.text = [self stringForInterfaceOrientation:interfaceOrientation];
        });
    }];
}

- (MDMotionOrientationUtil *)motionOrientationUtil {
    if (!_motionOrientationUtil) {
        _motionOrientationUtil = [MDMotionOrientationUtil new];
    }
    return _motionOrientationUtil;
}

#pragma mark -
#pragma mark - 系统方向变化的通知
/**
 *  设备方向枚举比界面方向多##正面朝上和正面朝下##两个枚举值
 *  设备方向向右指的是设备底部(Home按钮一端)向右，而界面方向向右指的设备顶部(状态栏一端)向右
 */
/// 设备方向变化 （比界面方向多了 正面朝上和正面朝下的方向枚举）
- (void)deviceOrientationChanged:(NSNotification *)notification {
    self.xxxxLabel.text = self.motionAcceleration.text;
    
    // 是否能变更取决去设备屏幕旋转是否锁定
    self.systemDeviceOrientationLabel.text = [self stringForDeviceOrientation:[UIDevice currentDevice].orientation];
}

/// 界面方向变化
- (void)interfaceOrientationChanged:(NSNotification *)notification {
    // 是否能变更取决去设备屏幕旋转是否锁定及APP内设置的Device Orientation值
    self.systemInterfaceOrientationLabel.text = [self stringForInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

#pragma mark -
#pragma mark - 将方向枚举转换成字符串显示
- (NSString *)stringForDeviceOrientation:(UIDeviceOrientation)orientation {
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            return @"Portrait";
        case UIDeviceOrientationPortraitUpsideDown:
            return @"PortraitUpsideDown";
        case UIDeviceOrientationLandscapeLeft:
            return @"LandscapeLeft";
        case UIDeviceOrientationLandscapeRight:
            return @"LandscapeRight";
        case UIDeviceOrientationFaceUp:
            return @"FaceUp";
        case UIDeviceOrientationFaceDown:
            return @"FaceDown";
        case UIDeviceOrientationUnknown:
        default:
            return @"Unknown";
    }
}

- (NSString *)stringForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return @"Portrait";
        case UIInterfaceOrientationPortraitUpsideDown:
            return @"PortraitUpsideDown";
        case UIInterfaceOrientationLandscapeLeft:
            return @"LandscapeLeft";
        case UIInterfaceOrientationLandscapeRight:
            return @"LandscapeRight";
        default:
            return @"Unknown";
    }
}

@end
