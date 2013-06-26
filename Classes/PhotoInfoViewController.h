//
//  PhotoInfoViewController.h
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

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "PicasaViewerAppDelegate.h"
#import "TextViewController.h"

/*!
 @class PhotoInfoViewController
 @discussion 写真の情報を表示するViewのController
 */

@interface PhotoInfoViewController : UITableViewController <PicasaFetchControllerDelegate,
UIAlertViewDelegate, TextViewControllerDelegate> {
	Photo *photo;
  BOOL canUpdate;
  PicasaFetchController *picasaController;
  NSManagedObjectContext *managedObjectContext;
  PhotoModelController *modelController;

}

/*!
 @property photo
 @discussion 表示対象のAlbum Object
 */
@property (nonatomic, retain) Photo *photo;

/*!
 @property canUpdate
 @discussion 写真情報の更新可能か
 */
@property (nonatomic) BOOL canUpdate;

/*!
 @property picasaController
 @discussion picasa アクセス controller
 */
@property (nonatomic, retain) PicasaFetchController *picasaController;
/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;


/*!
 @method initWithPhotoObject:
 @param photoObject photo model object
 @oaram fCanUpdate 更新可能か
 @discussion 表示対象のPhotoObjectを指定しての初期化
 */
- (id) initWithPhotoObject:(Photo *)photoObject canUpdate:(BOOL)fCanUpdate;

- (PicasaFetchController *) picasaController;

@end
