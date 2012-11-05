//
//  PhotoModelController.h
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
#import "Photo.h"

/*!
 @class PhotoModelController
 @discussion Photo Modelとのデータ入出力を行うController
 */
@interface PhotoModelController : NSObject <NSFetchedResultsControllerDelegate> {
  Album *album;

  NSFetchedResultsController *fetchedPhotosController;
  NSManagedObjectContext *managedObjectContext;
  
  // ローカルDB保存時の Lock Object
  NSLock  *lockSave;

}

/*!
 @method initWithContext:withAlbum
 @discussion 初期化
 @param context データオブジェクトのContext
 @param album Album Model Object
 */
- (id) initWithContext:(NSManagedObjectContext *)context withAlbum:(Album *)album;

/*!
 @property fetchedAlbumsController
 @discussion Album一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedPhotosController;

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*!
 @property album
 @discussion 現在選択されているAlbum
 */
@property (nonatomic, retain) Album *album;

/*!
 @method insertPhoto:withAlbum
 @discussion Photo情報をローカルDBに登録する.
 */
- (Photo *)insertPhoto:(GDataEntryPhoto *)photo withAlbum:(Album *)user;
/*!
 @method updateThumbnail:forPhoto
 @discussion PhotoのThumbnailをローカルDBに更新登録する.
 @return 正常であれば、挿入したModelObject, エラーであればnil
 */
- (Photo *)updateThumbnail:(NSData *)thumbnailData forPhoto:(Photo *)photo;

/*!
 @method removePhotos
 @discussion 現在のAlbumのPhotoデータを全て削除
 */
- (void)removePhotos;

/*!
 @method selectPhoto:hasError:
 @discussion 指定したPhotoのphoto model オブジェクトを得る
 */
- (Photo *)selectPhoto:(GDataEntryPhoto *)photo  hasError:(BOOL *)f;

/*!
 @method photoCount
 @discussion 写真数を返す
 */
- (NSUInteger)photoCount;


/*!
 @method photoAt:
 @discussion 指定したインデックスのPhoto Objectを返す
 */
- (Photo *)photoAt:(NSUInteger)index;

- (void) setLastAdd;

- (void) clearLastAdd;

@end
