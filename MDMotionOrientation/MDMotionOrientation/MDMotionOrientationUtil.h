//
//  MDMotionOrientationUtil.h
//  MDMotionOrientation
//
//  Created by hq on 2021/2/4.
//
//  通过设备运动加速计采集各轴上的加速度计算设备和界面的方向（无视设备或应用设置的方向锁定）
//  当iPhone设置锁定屏幕后，[[UIDevice currentDevice] orientation]无法获取到真实的设备方向
//  当应用设置单一界面方向后，[[UIApplication sharedApplication] statusBarOrientation]获取的界面方向是固定不变的
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDMotionOrientationUtil : NSObject

@property (nonatomic, assign, readonly) UIDeviceOrientation deviceOrientation;        /**<  设备方向  */
@property (nonatomic, assign, readonly) UIInterfaceOrientation interfaceOrientation;  /**<  界面方向（当应用设置了方向锁定时，界面方向也会采用设备的方向进行计算）  */

/// 开始加速计更新
/// @param handler 子线程中回调, 设备方向/用户界面方向/加速计数据
- (void)startAccelerometerUpdates:(void (^_Nullable)(UIDeviceOrientation deviceOrientation,
                                                     UIInterfaceOrientation interfaceOrientation,
                                                     CMAccelerometerData * _Nullable accelerometerData))handler;

/// 停止加速计更新
- (void)stopAccelerometerUpdates;

@end

NS_ASSUME_NONNULL_END
