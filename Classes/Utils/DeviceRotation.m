//
//  DeviceRotation.m
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

#import "DeviceRotation.h"

@interface DeviceRotation(Private)

/*!
 @method addObserveOriantationChange:
 @discussion 機器回転時のObserverを登録.
 */
- (void) addObserveOriantationChange;

/*!
 @method deviceRotated:
 @discussion デバイス回転の通知.登録されているDelegate先に通知を転送する.
 */
- (void) deviceRotated:(id)sender;

@end


@implementation DeviceRotation


@synthesize delegate;

- (id) initWithDelegate:(NSObject<DeviceRotationDelegate> *)newDelegate {
  self = [super init];
  if(self) {
    delegate = newDelegate;
    [self addObserveOriantationChange];
  }
  return self;
}


- (void) addObserveOriantationChange {
  UIDevice *device = [UIDevice currentDevice];
  
  // 端末回転を検知する為の初期化処理
  [device beginGeneratingDeviceOrientationNotifications];
  
  // delegate先を登録
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(deviceRotated:) 
                 name:UIDeviceOrientationDidChangeNotification object:nil];
  
}

- (void) deviceRotated:(id)sender {
  UIDevice *device = [UIDevice currentDevice];
  UIDeviceOrientation orientation = device.orientation;
  if(orientation == UIDeviceOrientationUnknown ||
     orientation == UIDeviceOrientationFaceUp ||
     orientation == UIDeviceOrientationFaceDown ) {
    return;
  }
  [self.delegate deviceRotated:orientation];
}


- (void) dealloc {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  
  [center removeObserver:self 
                    name:UIDeviceOrientationDidChangeNotification object:nil];
  [super dealloc];
}


@end
