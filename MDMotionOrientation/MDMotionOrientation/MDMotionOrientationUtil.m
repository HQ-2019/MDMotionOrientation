//
//  MDMotionOrientationUtil.m
//  MDMotionOrientation
//
//  Created by hq on 2021/2/4.
//

#import "MDMotionOrientationUtil.h"

@interface MDMotionOrientationUtil ()

@property (nonatomic, strong) CMMotionManager *motionManager;       /**<  运动服务管理对象  */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation MDMotionOrientationUtil

- (NSOperationQueue *)operationQueue {
    if (!_operationQueue) {
        _operationQueue = [NSOperationQueue new];
    }
    return _operationQueue;;
}

- (CMMotionManager *)motionManager {
    if (!_motionManager) {
        _motionManager = [CMMotionManager new];
        _motionManager.accelerometerUpdateInterval = 1.0 / 60.0;   // 设置加速计更新的时间间隔
    }
    return _motionManager;
}

#pragma mark -
#pragma mark - 加速计处理
/// 停止加速计更新
- (void)stopAccelerometerUpdates {
    [self.motionManager stopAccelerometerUpdates];
}

/// 开始加速计更新
/// @param handler 子线程中回调, 设备方向/用户界面方向/加速计数据
- (void)startAccelerometerUpdates:(void (^_Nullable)(UIDeviceOrientation deviceOrientation,
                                                     UIInterfaceOrientation interfaceOrientation,
                                                     CMAccelerometerData * _Nullable accelerometerData))handler {
    // 判断设备是否可用加速计
    if (![self.motionManager isAccelerometerAvailable]) {
        return;
    }
    
    // 启动加速计更新
    __weak typeof(self) weakSelf = self;
    [self.motionManager startAccelerometerUpdatesToQueue:self.operationQueue
                                             withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
        // 各轴上的加速度
        // x轴:  -1:设备左侧在上右侧在下，1:设备右侧在上左侧在下
        // y轴:  -1:设备直立，1:设备倒立
        // z轴:  -1:设备正面朝上，1:设备正面朝下
        CMAcceleration acceleration = accelerometerData.acceleration;
        float xx = -acceleration.x;
        float yy = acceleration.y;
        float zz = acceleration.z;
        // x轴和y轴旋转的角度
        float angle = atan2(yy, xx);
        
        // 计算方向
        UIDeviceOrientation newDeviceOrientation = [self deviceOrientationWithCurrentDeviceOrientation:weakSelf.deviceOrientation angle:angle z:zz];
        UIInterfaceOrientation newInterfaceOrientation = [self interfaceOrientationWithCurrentInterfaceOrientation:weakSelf.interfaceOrientation angle:angle z:zz];
        
        self->_deviceOrientation = newDeviceOrientation;
        self->_interfaceOrientation = newInterfaceOrientation;
        
        if (handler) {
            handler(weakSelf.deviceOrientation, weakSelf.interfaceOrientation, accelerometerData);
        }
    }];
}

/// 计算设备方向
/// @param deviceOrientation 设备最近一次的方向
/// @param angle 设备yx轴上旋转的角度，主要用来判断左右方向
/// @param z 设备在z轴承的加速度，主要用来判断设备正面朝上还是朝下
- (UIDeviceOrientation)deviceOrientationWithCurrentDeviceOrientation:(UIDeviceOrientation)deviceOrientation angle:(float)angle z:(float)z {
    float absoluteZ = (float)fabs(z);
    
    if (deviceOrientation == UIDeviceOrientationFaceUp || deviceOrientation == UIDeviceOrientationFaceDown) {
        if (absoluteZ < 0.86f) {
            if (angle < -2.60f) {
                deviceOrientation = UIDeviceOrientationLandscapeRight;
            } else if (angle > -2.05f && angle < -1.10f) {
                deviceOrientation = UIDeviceOrientationPortrait;
            } else if (angle > -0.48f && angle < 0.48f) {
                deviceOrientation = UIDeviceOrientationLandscapeLeft;
            } else if (angle > 1.08f && angle < 2.08f) {
                deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            }
        } else if (z < 0.0f) {
            deviceOrientation = UIDeviceOrientationFaceUp;
        } else if (z > 0.0f) {
            deviceOrientation = UIDeviceOrientationFaceDown;
        }
    } else {
        if (z > 0.88f) {
            deviceOrientation = UIDeviceOrientationFaceDown;
        } else if (z < -0.88f) {
            deviceOrientation = UIDeviceOrientationFaceUp;
        } else {
            switch (deviceOrientation) {
                case UIDeviceOrientationLandscapeLeft:
                    if (angle < -1.10f) {
                        return UIDeviceOrientationPortrait;
                    }
                    if (angle > 1.10f) {
                        return UIDeviceOrientationPortraitUpsideDown;
                    }
                    break;
                    
                case UIDeviceOrientationLandscapeRight:
                    if (angle < 0.0f && angle > -2.05f) {
                        return UIDeviceOrientationPortrait;
                    }
                    if (angle > 0.0f && angle < 2.05f) {
                        return UIDeviceOrientationPortraitUpsideDown;
                    }
                    break;
                    
                case UIDeviceOrientationPortraitUpsideDown:
                    if (angle > 2.66f) {
                        return UIDeviceOrientationLandscapeRight;
                    }
                    if (angle < 0.48f) {
                        return UIDeviceOrientationLandscapeLeft;
                    }
                    break;
                    
                case UIDeviceOrientationPortrait:
                default:
                    if (angle > -0.43f) {
                        return UIDeviceOrientationLandscapeLeft;
                    }
                    if (angle < -2.7f) {
                        return UIDeviceOrientationLandscapeRight;
                    }
                    break;
            }
        }
    }
    return deviceOrientation;
}

/// 计算用户界面方向
/// @param interfaceOrientation 用户界面最近一次的方向
/// @param angle 设备yx轴上旋转的角度，主要用来判断左右方向
/// @param z 设备在z轴承的加速度，主要用来判断设备正面朝上还是朝下（用户界面忽略设备正面的朝向）
- (UIInterfaceOrientation)interfaceOrientationWithCurrentInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation angle:(float)angle z:(float)z {
    UIDeviceOrientation deviceOrientation = [self deviceOrientationWithCurrentDeviceOrientation:[self deviceOrientationForInterfaceOrientation:interfaceOrientation] angle:angle z:z];
    return [self interfaceOrientationForDeviceOrientation:deviceOrientation interfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark - 设备方向和界面方向相互转换

/**
 *  设备方向枚举比界面方向多【正面朝上】和【正面朝下】两个枚举值
 *  设备方向向右指的是设备底部(Home按钮一端)向右，而界面方向向右指的设备顶部(状态栏一端)向右
 */

/// 界面方向转设备方向
- (UIDeviceOrientation)deviceOrientationForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return UIDeviceOrientationLandscapeRight;
            
        case UIInterfaceOrientationLandscapeRight:
            return UIDeviceOrientationLandscapeLeft;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return UIDeviceOrientationPortraitUpsideDown;

        default:
            return UIDeviceOrientationPortrait;
    }
}

/// 设备方向转界面方向
- (UIInterfaceOrientation)interfaceOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
                                              interfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            return UIInterfaceOrientationPortrait;
            
        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeRight;
            
        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeLeft;
            
        case UIDeviceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationPortraitUpsideDown;
            
        default:
            return interfaceOrientation;
    }
}

@end
