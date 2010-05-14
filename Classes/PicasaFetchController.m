//
//  PicasaFetchController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

@end


@implementation PicasaFetchController

@synthesize delegate;

- (void) queryUserAndAlbums:(NSString *)user {
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  // アカウント設定
  //  [service setUserCredentialsWithUsername:@"nyaago69" password:@"********"];
  
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

- (void) queryAlbumAndPhotos:(NSString *)albumId user:(NSString *)userId {
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  
  // アカウント設定
  //  [service setUserCredentialsWithUsername:@"nyaago69" password:@"********"];
  
  NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:userId
                                                           albumID:albumId
                                                         albumName:nil
                                                           photoID:nil
                                                              kind:@"photo"
                                                            access:nil];
  GDataQueryGooglePhotos *query = [GDataQueryGooglePhotos queryWithFeedURL:feedURL];
  //  [query setMaxResults:25];
  [query setThumbsize:64];
  [query setImageSize:800];
  NSLog(@"queryAlbumAndPhotos URL =  %@", [query URL]);
  [service 	fetchFeedWithURL:[query URL]
                    delegate:self 
           didFinishSelector:@selector(albumAndPhotosWithTicket:finishedWithAlbumFeed:error:) ];
  [service release];
  
}

- (void) queryPhoto:(NSString *)photo album:(NSString *)albumId user:(NSString *)userId {
  GDataServiceGooglePhotos *service = [[GDataServiceGooglePhotos alloc] init];
  
  // アカウント設定
  //  [service setUserCredentialsWithUsername:@"nyaago69" password:@"********"];
  
  NSURL *feedURL = [GDataServiceGooglePhotos photoFeedURLForUserID:userId
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
  }
  if(delegate && 
     [delegate 
      respondsToSelector:@selector(userAndAlbumsWithTicket:finishedWithUserFeed:error:)] ) {
       [delegate userAndAlbumsWithTicket:ticket 
                    finishedWithUserFeed:feed 
                                   error:error];
     }
}

- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error {
  if (error != nil) {  
    NSLog(@"fetch error: %@", error);
  }
  if(delegate &&
     [delegate
      respondsToSelector:@selector(albumAndPhotosWithTicket:finishedWithAlbumFeed:error:)] ) {
       [delegate albumAndPhotosWithTicket:ticket 
                    finishedWithAlbumFeed:feed 
                                    error:error];
     }
  
}

- (void)photoWithTicket:(GDataServiceTicket *)ticket
  finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                  error:(NSError *)error {
  if (error != nil) {  
    NSLog(@"fetch error: %@", error);
  }
  if(delegate &&
     [delegate respondsToSelector:@selector(photoWithTicket:finishedWithPhotoFeed:error:)]) {
    [delegate photoWithTicket:ticket 
        finishedWithPhotoFeed:feed 
                        error:error];
  }
}



@end
