//
//  SettingsManager.m
//  PicasaViewer
//
//  Created by nyaago on 10/05/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsManager.h"

@interface SettingsManager (Private) 

/*!
 @method stringForKey:withDefault
 @discussion 指定したKeyの文字列値を返す
 */
- (NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defaultValue;

/*!
 @method setObject:forKey
 @discussion 指定したKeyの値を設定する
 */
- (void)setObject:(id)object forKey:(NSString *)key;

@end

@implementation SettingsManager


- (void) setUserId:(NSString *)userId {
  [self setObject:userId forKey:@"userId"];
}

- (NSString *) userId {
  return [self stringForKey:@"userId" withDefault:@""];
}

- (void) setPassword:(NSString *)password {
  [self setObject:password forKey:@"password"];
}

- (NSString *) password {
  return [self stringForKey:@"password" withDefault:@""];
}


#pragma mark Private

- (NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defaultValue {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *value = [userDefaults stringForKey:key];
  if(!value)
    value = defaultValue;
  
  [pool drain];
	return value;
}

- (void)setObject:(id)object forKey:(NSString *)key {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:object forKey:key];
  [userDefaults synchronize];
  
  [pool drain];
}


@end
