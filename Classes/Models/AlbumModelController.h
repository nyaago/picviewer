//
//  AlbumModelController.h
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
#import "PicasaFetchController.h"

#import "Album.h"
#import "User.h"
/*!
 @class AlbumModelController
 @discussion Album Modelとのデータ入出力を行うController
 */

@interface AlbumModelController : NSObject <NSFetchedResultsControllerDelegate> {
  User *user;
  
  NSFetchedResultsController *fetchedAlbumsController;
  NSManagedObjectContext *managedObjectContext;

}

/*!
 @method initWithContext:withAlbum
 @discussion 初期化
 @param context データオブジェクトのContext
 @param user User Model Object
 */
- (id) initWithContext:(NSManagedObjectContext *)context withUser:(User *)user;

/*!
 @property fetchedAlbumsController
 @discussion Album一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedAlbumsController;

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;


/*!
 @property user
 @discussion 現在選択されているUser
 */
@property (nonatomic, retain) User *user;

/*!
 @method albumCount
 @discussion album数を返す
 */
-(NSUInteger) albumCount;

/*!
 @method albumAt:
 @discussion 指定したindexのalbum model objectを返す
 @param index 
 @param Album オブジェクト
 */
-(Album *) albumAt:(NSIndexPath *)index;

/*!
 @method insertAlbum:withUser;
 @discussion Album情報をローカルDBに登録する.
 @param album - GoogleDataのAlbumEntry
 @param withUser - CoreDataのuser Object
 @return 更新結果のCoreDataのAlbumObject
 */
- (Album *)insertAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject;

/*!
 @method updateAlbum:withGDataAlbum:withUser
 @discussion Album情報をローカルDBに変更登録する.
 @param album - GoogleDataのAlbumEntry
 @param withUser - CoreDataのuser Object
 @return 更新結果のCoreDataのAlbumObject
 */
- (Album *)updateAlbum:(Album *)albumObject 
        withGDataAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject;

/*!
 @method deleteAlbum:
 @discussion Album情報をローカルDBに登録する.
 @param albumObject 削除対象のAlbum
 @param user 参照元のUser
 */
- (void)deleteAlbum:(Album *)albumObject withUser:(User *)userObject;


- (void)deleteAlbumsWithUserFeed:(GDataFeedPhotoUser *)album 
                        withUser:(User *)userObject
                        hasError:(BOOL *)f;



/*!
 @method selectAlbum
 @discussion AlbumのManagedObjectを取得する
 */
- (Album *)selectAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject hasError:(BOOL *)f;


/*!
 @method updateThumbnail:forAlbum
 @discussion アルバムのThumbnailをローカルDBに更新登録する.
 */
- (Album *)updateThumbnail:(NSData *)thumbnailData forAlbum:(Album *)album;


@end
