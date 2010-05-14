//
//  DeviceRotation.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

- (id) initWithDelegate:(id<DeviceRotationDelegate>)newDelegate {
  self = [super init];
  if(self) {
    delegate = newDelegate;
    [delegate retain];
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
  NSLog(@"deviceRotated");
  if(orientation == UIDeviceOrientationUnknown ||
     orientation == UIDeviceOrientationFaceUp ||
     orientation == UIDeviceOrientationFaceDown ) {
    return;
  }
  [lock lock];
  [self.delegate deviceRotated:orientation];
  [lock unlock];
}


- (void) dealloc {
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  
  [center removeObserver:self 
                    name:UIDeviceOrientationDidChangeNotification object:nil];
  [lock lock];
  [delegate release];
  [lock unlock];
  [super dealloc];
}


@end
