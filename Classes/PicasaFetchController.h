//
//  PicasaFetchController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GDataPhotos.h"

/*!
 @protocal PicasaFetchControllerDelegate
 Picasaデータ取得のリクエストの結果の通知を受けるためのProtocal
 */
@protocol PicasaFetchControllerDelegate

@optional

/*!
 @method userAndAlbumsWithTicket:finishedWithUserFeed:error:
 @discussion PicasaFetchControllerのqueryUserAndAlbums:でのリクエストに対する通知メソッド
 */
- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error ;
/*!
 @method albumAndPhotosWithTicket:finishedWithAlbumFeed:error:
 @discussion PicasaFetchControllerのqueryAlbumAndPhotos:user:
 でのリクエストに対する通知メソッド
 */
- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error ;
/*!
 @method photoWithTicket:finishedWithPhotoFeed:error:
 @discussion PicasaFetchControllerのqueryPhoto:album:user:
 でのリクエストに対する通知メソッド
 */
- (void)photoWithTicket:(GDataServiceTicket *)ticket
  finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                  error:(NSError *)error;

@end


/*!
 @class PicasaFetchController
 Picasaデータ取得のリクエスト.
 各メソッドは、非同期にリクエストを行い、delegateで定義されているメソッドで取得の通知が行われる.
 */
@interface PicasaFetchController : NSObject {
  NSInteger maxResults;
  NSInteger thumbSize;
  NSInteger imageSize;
  NSObject  <PicasaFetchControllerDelegate> *delegate;
}

@property (nonatomic, retain) NSObject <PicasaFetchControllerDelegate> *delegate;

/*!
 @method queryUserAndAlbums
 @discussion 指定したユーザのユーザ情報とそのユーザのアルバムの一覧取得のリクエスト
 delegateのuserAndAlbumsWithTicket:finishedWithUserFeed:error:で通知を受ける.
 @param user user id
 */
- (void) queryUserAndAlbums:(NSString *)user;
/*!
 @method queryAlbumAndPhotos:user
 @discussion 指定したユーザ/アルバムのアルバム情報とそのアルバムの写真一覧取得のリクエスト
 delegateのalbumAndPhotosWithTicket:finishedWithAlbumFeed:error:で通知を受ける
 @param albumId album id
 @param userId user id
 */
- (void) queryAlbumAndPhotos:(NSString *)albumId user:(NSString *)userId;
/*!
 @method queryPhoto:album:user
 @discussion 指定したユーザ/アルバム/写真IDの写真情報を取得
 delegateのphotoWithTicket:finishedWithPhotoFeed:error:で通知を受ける
 @param photo photo id
 @param albumId
 @param userId
 */
- (void) queryPhoto:(NSString *)photo album:(NSString *)albumId user:(NSString *)userId;

@end




