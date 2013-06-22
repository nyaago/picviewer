//
//  PicasaFetchController.h
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

/*!
 @method insertedPhotoWithTicket:finishedWithPhotoFeed:error:
 @discussion PicasaFetchControllerのinsertPhoto:photoData withAlbum: （photoアップロード）
 でのリクエストに対する通知メソッド
 */
- (void)insertedPhotoWithTicket:(GDataServiceTicket *)ticket
  finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                  error:(NSError *)error;

/*!
 @method deleted:error:
 @discussion PicasaFetchControllerのdeletePhoto:album: （photo削除）
 でのリクエストに対する通知メソッド
 */
- (void)deletedPhoto:(GDataEntryPhoto *)entry
                          error:(NSError *)error;



/*!
 @method PicasaFetchWasError:
 @discussion 認証エラーの場合の通知メソッド
 */
- (void) PicasaFetchWasError:(NSError *)error;


/*!
 @method PicasaFetchNoUser:
 @discussion 検索対象のユーザがいなかった場合の通知メソッド
 */
- (void) PicasaFetchNoUser:(NSError *)error;

/*!
 @method PicasaFetchWasError:
 @discussion 認証、ユーザなし以外のエラーの場合の通知メソッド
 */
- (void) PicasaFetchWasAuthError:(NSError *)error;



@end


/*!
 @class PicasaFetchController
 Picasaデータ取得のリクエスト.
 各メソッドは、非同期にリクエストを行い、delegateで定義されているメソッドで取得の通知が行われる.
 */
@interface PicasaFetchController : NSObject {
  NSInteger maxResults;
  NSObject  <PicasaFetchControllerDelegate> *delegate;
	// 処理が完了している  
  BOOL completed;
  // 停止が要求されている?
  BOOL stoppingRequired;
  // ステタースの設定、取得のさいのLockオブジェクト
  NSLock *lock;
  // Google User Id
  NSString *userId;
  // Google Password
  NSString *password;
  // upload するphoto データー
  NSData *imageData;
  
}

/*!
 @property uploadURL
 @discussuion photo upload の URL
 */
@property (nonatomic, retain) NSURL *uploadURL;

@property (nonatomic, assign) NSObject <PicasaFetchControllerDelegate> *delegate;

/*!
 @property userId
 @discussion Google User Id
 */
@property (nonatomic, retain) NSString *userId;
/*!
 @property password
 @discussion Google Password
 */
@property (nonatomic, retain) NSString *password;


/*!
 @method insertPhoto:photoData withAlbum:
 @discussion Photoのアップロード
 delegateのinsertedPhotoWithTicket:finishedWithPhotoFeed:error:で通知を受ける
 @param photoData pngデーター
 @param album album id
 */
- (void) insertPhoto:(NSData *)photoData withAlbum:(NSString *)album withUser:(NSString *)user;

/*!
 @method deletePhoto:album:
 @discussion photoの削除
 @param photoId
 @param albumId
 @param user  - user id
 */
- (void) deletePhoto:(NSString *)photoId album:(NSString *)albumId user:(NSString *)user;

/*!
 @method queryUserAndAlbums
 @discussion 指定したユーザのユーザ情報とそのユーザのアルバムの一覧取得のリクエスト
 delegateのuserAndAlbumsWithTicket:finishedWithUserFeed:error:で通知を受ける.
 @param user user id
 */
- (void) queryUserAndAlbums:(NSString *)user;

/*!
 @method queryAlbum:withUser:completionHandler:
 @discussion 指定したユーザのユーザ情報とそのユーザのアルバムの一覧取得のリクエスト
 @param user user id
 @param handler
 */
- (void) queryAlbum:(NSString *)albumId withUser:(NSString *)user
  completionHandler:(void (^)(GDataServiceTicket *ticket, GDataFeedPhotoAlbum *feed, NSError *error))handler;

/*!
 @method queryAlbumAndPhotos:user
 @discussion 指定したユーザ/アルバムのアルバム情報とそのアルバムの写真一覧取得のリクエスト
 delegateのalbumAndPhotosWithTicket:finishedWithAlbumFeed:error:で通知を受ける
 @param albumId album id
 @param userId user id
 @param photoSize 写真のサイズ
 @param thumbSize サムネイルのサイズ
 */
- (void) queryAlbumAndPhotos:(NSString *)albumId user:(NSString *)userId
withPhotoSize:(NSNumber *)photoSize withThumbSize:(NSNumber *)thumbSize;
/*!
 @method queryPhoto:album:user
 @discussion 指定したユーザ/アルバム/写真IDの写真情報を取得
 delegateのphotoWithTicket:finishedWithPhotoFeed:error:で通知を受ける
 @param photo photo id
 @param albumId
 @param userId
 */
- (void) queryPhoto:(NSString *)photo album:(NSString *)albumId user:(NSString *)userId;

/*!
 @method requireStopping
 @discussion 処理停止の要求
 */
- (void)requireStopping;

/*!
 @method waitCompleted
 @discussion 処理が完了するまで待つ,まだ開始されていない場合は、すぐに返る。
 */
//- (void) waitCompleted;

/*!
 @property completed
 @return データー取得が完了しているか
 */
@property (nonatomic, readonly) BOOL completed;

@end




