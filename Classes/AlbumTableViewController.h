//
//  AlbumTableViewController.h
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
#import "User.h"
#import "PicasaFetchController.h"
#import "QueuedURLDownloader.h"
#import "AlbumModelController.h"

/*!
 @class AlbumTableViewController
 @discussion アルバム一覧のView
 */
@interface AlbumTableViewController : UITableViewController 
<NSFetchedResultsControllerDelegate, PicasaFetchControllerDelegate, 
QueuedURLDownloaderDelegate> {
  
  AlbumModelController *modelController;
  NSManagedObjectContext *managedObjectContext;
  User *user;
  QueuedURLDownloader *downloader;
  UIBarButtonItem *backButton;
  BOOL hasErrorInDownloading;
  BOOL hasErrorInInsertingThumbnail;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;
  // Picasaデータ取得コントローラー
  PicasaFetchController *picasaFetchController;
	// データロード中 
  BOOL onLoad;
  // データロード中のロック
  NSLock *onLoadLock;
  // refresh Button
  UIBarButtonItem *refreshButton;
}


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
 @method backAction:
 Back Action
 */
- (void) backAction:(id)sender;

/*!
 @method backButton
 @discussion 戻るボタン返す
 */
- (UIBarButtonItem *)backButton;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method setUser
 @discussion 
 */
- (void)setUser:(User *)newUser;

@end
