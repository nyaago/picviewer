//
//  SettingsManager.m
//  PicasaViewer
//
//  Created by nyaago on 10/05/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsManager.h"

static NSInteger imageSizes[3] = {640, 1280, 1600};

@interface SettingsManager (Private) 

/*!
 @method stringForKey:withDefault
 @discussion 指定したKeyの文字列値を返す
 */
- (NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defaultValue;

/*!
 @method objectForKey:withDefault
 @discussion 指定したKeyの値を返す
 */
- (NSObject *)objectForKey:(NSString *)key withDefault:(NSObject *)defaultValue;



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


- (void) setCurrentUser:(NSString *)user {
  [self setObject:user forKey:@"currentUser"];
}

- (NSString *)currentUser {
 return [self stringForKey:@"currentUser" withDefault:nil];
}

- (void) setCurrentAlbum:(NSString *)albumId {
  [self setObject:albumId forKey:@"currentAlbum"];
}

- (NSString *)currentAlbum {
 return  [self stringForKey:@"currentAlbum" withDefault:nil];
}


- (void) setImageSize:(NSInteger)size {
  [self setObject:[NSNumber numberWithInt:size] forKey:@"imageSize"];
}

- (NSInteger) imageSize {
  NSNumber *n = (NSNumber *)[self objectForKey:@"imageSize" 
                       withDefault:[NSNumber numberWithInt:1280]];
  return [n intValue];
}


+ (NSInteger)imageSizeToIndex:(NSInteger)size {
  int c = sizeof(imageSizes)  / sizeof(imageSizes[0]);
  NSInteger index = 1;
  for(int i = 0; i < c; ++i) {
    if(size == imageSizes[i]) {
      index = i;
      break;
    }
  }
  return index;
}


+ (NSInteger)indexToImageSize:(NSInteger)index {
  int c = sizeof(imageSizes)  / sizeof(imageSizes[0]);
  if(index >= c)
    return 1280;
  return imageSizes[index];
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

- (NSObject *)objectForKey:(NSString *)key withDefault:(NSString *)defaultValue {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSObject *value = [userDefaults objectForKey:key];
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
