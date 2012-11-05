//
//  DeviceRotatation.h
//  PicasaViewer
//
//--
// Copyright (c) 2012 nyaago
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//++

#import <Foundation/Foundation.h>

/*!
 @protocol DeviceRotation
 @discussion デバイス回転の通知先Delegate.DeviceRotationクラスでこのProtocol実装クラス
			インスタンスを通知先として登録する。
 */
@protocol DeviceRotationDelegate

/*!
 @method deviceRotated:
 @discussion デバイスの向きが変わった時の通知
 @param orientation 現在のデバイスの向き
 */
-(void) deviceRotated:(UIDeviceOrientation)orientation;

@end


/*!
 @class DeviceRotation
 @discussion デバイス回転の通知の管理
 */
@interface DeviceRotation : NSObject {
  NSObject <DeviceRotationDelegate> *delegate;
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

