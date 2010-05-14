//
//  DeviceRotatation.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class DeviceRotation
 @discussion デバイス回転の通知先Delegate.DeviceRotationクラスでこのProtocol実装クラス
			インスタンスを通知先として登録する。
 */
@protocol DeviceRotationDelegate

-(void) deviceRotated:(UIDeviceOrientation)orientation;

@end


/*!
 @class DeviceRotation
 @discussion デバイス回転の通知の管理
 */
@interface DeviceRotation : NSObject {
  id <DeviceRotationDelegate> delegate;
  NSLock *lock;
}

/*!
 @property delegate
 @discussion デバイス回転通知先のDelegate
 */
@property (nonatomic, retain) id <DeviceRotationDelegate> delegate;

/*!
 @method initWithDelegate:
 @discussion デバイス回転通知先のDelegateを指定しての初期化
 */
- (id) initWithDelegate:(id<DeviceRotationDelegate>)delegate;



  
@end

