//
//  PicasaFetchController.m
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

#import "PicasaFetchController.h"

@interface PicasaFetchController (Private)
- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error ;
- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error ;
- (void)photoWithTicket:(GDataServiceTicket *)ticket
  finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                  error:(NSError *)error;

- (void) handleError:(NSError *)error;

/*!
 @method revicedThumbSize:
 @discussion サムネイルのサイズを有効なサイズに補正
 */
- (NSNumber *) revicedThumbSize:(NSNumber *)size;

@end


@implementation PicasaFetchController

static NSUInteger  thumbSizes[] = {32, 48, 64, 72, 104, 144, 150, 160};

@synthesize delegate;
@synthesize userId;
@synthesize password;

- (id) init {
  self = [super init];
  if(self) {
    lock = [[NSLock alloc] init];
    completed = YES;
  }
  return self;
}

- (void) dealloc {
  [lock release];
	[super dealloc];
}

- (void) queryUserAndAlbums:(NSString *)user {
  completed = NO;
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  // アカウント設定
  if(userId && password) {
    NSLog(@"user = %@, password = %@", userId, password);
	  [service setUserCredentialsWithUsername:userId password:password];
  }
  NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:user 
                                                           albumID:nil
                                                         albumName:nil
                                                           photoID:nil
                                                              kind:@"album"
                                                            access:nil];
  GDataQueryGooglePhotos *query = [GDataQueryGooglePhotos queryWithFeedURL:feedURL];
  //  [query setMaxResults:25];
  [query setThumbsize:64];
  [query setImageSize:64];
  
  NSLog(@"queryUserAndAlbums URL = %@", [query URL]);
  [service 	fetchFeedWithURL:[query URL]
                    delegate:self 
           didFinishSelector:@selector(userAndAlbumsWithTicket:finishedWithUserFeed:error:)];
  [service release];
}

- (void) queryAlbumAndPhotos:(NSString *)albumId user:(NSString *)targetUserId 
               withPhotoSize:(NSNumber *)photoSize
               withThumbSize:(NSNumber *)thumbSize {
  completed = NO;
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  
  // アカウント設定
  if(userId && password) {
	  [service setUserCredentialsWithUsername:userId password:password];
  }
  NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:targetUserId
                                                           albumID:albumId
                                                         albumName:nil
                                                           photoID:nil
                                                              kind:@"photo"
                                                            access:nil];
  GDataQueryGooglePhotos *query = [GDataQueryGooglePhotos queryWithFeedURL:feedURL];
  //  [query setMaxResults:25];
  [query setThumbsize:[[self revicedThumbSize:thumbSize] intValue]];
  if(photoSize) {
  	[query setImageSize:[photoSize intValue  ]];
  }
  NSLog(@"queryAlbumAndPhotos URL =  %@", [query URL]);
  [service 	fetchFeedWithURL:[query URL]
                    delegate:self 
           didFinishSelector:@selector(albumAndPhotosWithTicket:finishedWithAlbumFeed:error:) ];
  [service release];
  
}

- (void) queryPhoto:(NSString *)photo album:(NSString *)albumId 
               user:(NSString *)targetUserId {
  completed = NO;
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  
  // アカウント設定
  if(userId && password) {
	  [service setUserCredentialsWithUsername:userId password:password];
  }
  NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:targetUserId
                                                           albumID:albumId
                                                         albumName:nil
                                                           photoID:photo
                                                              kind:nil
                                                            access:nil];
  GDataQueryGooglePhotos *query = [GDataQueryGooglePhotos queryWithFeedURL:feedURL];
  //  [query setKind:@"photo"];
  [query setMaxResults:25];
  [query setThumbsize:64];
  [query setImageSize:64];
  NSLog(@"queryPhoto = %@", [query URL]);
  [service 	fetchFeedWithURL:[query URL]
                    delegate:self 
           didFinishSelector:@selector(photoWithTicket:finishedWithPhotoFeed:error:) ];
  [service release];
  
}


- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error {
  if (error != nil) {  
    NSLog(@"fetch error: %@", error);
    [self handleError:error];
    return;
  }
  
  NSLog(@"ticket = %@", ticket);
  // 停止要求されていれば、処理中断
  [lock lock];
  if(stoppingRequired) {
    completed = YES;
    [lock unlock];
    return;
  }
  [lock unlock];
  if(delegate && 
     [delegate 
      respondsToSelector:@selector(userAndAlbumsWithTicket:finishedWithUserFeed:error:)] ) {
       [delegate userAndAlbumsWithTicket:ticket 
                    finishedWithUserFeed:feed 
                                   error:error];
     }
  /*
  [lock lock];
  completed = YES;
  [lock unlock];
   */
}

- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error {
  if (error != nil) {  
    NSLog(@"fetch error: %@", error);
    [self handleError:error];
    return;
  }
  // 停止要求されていれば、処理中断
  [lock lock];
  if(stoppingRequired) {
    completed = YES;
    [lock unlock];
    return;
  }
  [lock unlock];
  if(delegate &&
     [delegate
      respondsToSelector:@selector(albumAndPhotosWithTicket:finishedWithAlbumFeed:error:)] ) {
       [delegate albumAndPhotosWithTicket:ticket 
                    finishedWithAlbumFeed:feed 
                                    error:error];
  }
  [lock lock];
  completed = YES;
  [lock unlock];
}

- (void)photoWithTicket:(GDataServiceTicket *)ticket
  finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                  error:(NSError *)error {
  if (error != nil) {  
    NSLog(@"fetch error: %@", error);
    [self handleError:error];
    return;
  }
  // 停止要求されていれば、処理中断
  [lock lock];
  if(stoppingRequired) {
    completed = YES;
    [lock unlock];
    return;
  }
  [lock unlock];
  if(delegate &&
     [delegate respondsToSelector:@selector(photoWithTicket:finishedWithPhotoFeed:error:)]) {
    [delegate photoWithTicket:ticket 
        finishedWithPhotoFeed:feed 
                        error:error];
  }
  /*
  [lock lock];
  completed = YES;
  [lock unlock];
   */
}


- (NSNumber *) revicedThumbSize:(NSNumber *)size {
  NSUInteger result  = thumbSizes[sizeof(thumbSizes) / sizeof(NSUInteger) - 1];
  for(NSUInteger  i = 0; i < sizeof(thumbSizes) / sizeof(NSUInteger); ++i) {
    if([size integerValue] <= thumbSizes[i]) {
      result = thumbSizes[i];
      break;
    }
  }
  return [NSNumber numberWithInteger:result];
}

- (void)requireStopping {
  [lock lock];
  stoppingRequired = YES;
  [lock unlock];
}

- (void) waitCompleted {
  BOOL ret = NO;
  while (YES) {
    [lock lock];
    ret = completed;
    [lock unlock];
    if(ret == YES) {
      break;
    }
    [NSThread sleepForTimeInterval:0.01f];
  }
}


- (void) handleError:(NSError *)error {
  if(!error)
    return;
  if([error code] == 404) {	// ユーザなし
    if( delegate && 
     [delegate respondsToSelector:@selector(PicasaFetchNoUser:)] ) {
      [delegate PicasaFetchNoUser:error];
    }
  }
  else if([error code] == 403) { // 認証エラー
    if( delegate && 
       [delegate respondsToSelector:@selector(PicasaFetchWasAuthError:)] ) {
      [delegate PicasaFetchWasAuthError:error];
    }
  }
  else {
    if( delegate && 
       [delegate respondsToSelector:@selector(PicasaFetchWasError:)] ) {
      [delegate PicasaFetchWasError:error];
    }
  }
  
}


@end
