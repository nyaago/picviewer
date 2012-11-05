//
//  PhotoListViewController.h
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
#import "PicasaFetchController.h"
#import "QueuedURLDownloader.h"
#import "PageControlViewController.h"
#import "AlbumTableViewController.h"
#import "ThumbImageView.h"
#import "AlbumTableViewControllerDelegate.h"
#import "Album.h"
#import "Photo.h"
#import "PhotoModelController.h"
#import "LabeledProgressView.h"

@interface PhotoListViewController : UIViewController
<PicasaFetchControllerDelegate, 
QueuedURLDownloaderDelegate, PageControlViewControllerDataSource,
UIAlertViewDelegate,UISplitViewControllerDelegate,AlbumTableViewControllerDelegate,
ThumbImageViewDelegate> {
  
  @private
  
  Album *album;
  
  NSManagedObjectContext *managedObjectContext;
  
  PhotoModelController *modelController;
  QueuedURLDownloader *downloader;
  
  UIBarButtonItem *backButton;
  UIBarButtonItem *indexButton;
  UIScrollView *scrollView;
  LabeledProgressView *progressView;
  // ローカルDB保存時の Lock Object
  NSLock  *lockSave;
  // Download中にエラーが発生したか?
  BOOL hasErrorInDownloading;
  // Thumbnailの登録中にエラーが発生したか?
  BOOL hasErrorInInsertingThumbnail;
  BOOL onScroll;
  
  // Thumbnail表示処理中にOnになるフラグ
  BOOL onAddingThumbnails;
  // Thumbnail表示中フラグの同期変数
  NSLock *onAddingThumbnailsLock;
  // Thumbnail表示処理の中断が要求されている?
  BOOL stoppingToAddingThumbnailsRequred;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;
  // Picasaデータ取得コントローラー
  PicasaFetchController *picasaFetchController;
  // refresh Button
  UIBarButtonItem *refreshButton;
  // view information Button
  UIBarButtonItem *infoButton;
  // 再ロード中ならYES
  BOOL onRefresh;
  // album一覧Viewからの遷移の場合YES
  BOOL isFromAlbumTableView;
  // サムネイル処理のLock
  NSLock *thumbnailLock;
  // 現在layoutされている向き
  UIDeviceOrientation layoutedOrientation;
  //
  UILabel *noPhotoLabel;

}

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*!
 @property album
 @discussion 現在選択されているUser
 */
@property (nonatomic, retain) Album *album;

/*!
 @property scrollView
 @discussion Tumbnailを配置するScroolView
 */
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

/*!
 @property progressView
 @discussion ダウンロード処理中に表示するProgressBar のView
 */
@property (nonatomic, retain) IBOutlet LabeledProgressView *progressView;

/*!
 @method loadThumbnails
 @discussion サムネイルを表示する.
 */
- (void)loadThumbnails;

/*!
 @method discardTumbnails
 @discussion 表示しているサムネイルの破棄
 */
- (void)discardTumbnails;

/*!
 @method thumbnailAt:
 @discussion 指定したIndexの画像のUIImageViewを返す
 @param index 0起点のindex
 @return UIImageView
 */
- (UIImageView *)thumbnailAt:(NSUInteger)index;


/*!
 @method backButton
 @discussion 戻るボタン返す
 */
- (UIBarButtonItem *)backButton;

/*!
 @method indexButton
 @discussion インデックス表示ボタン返す
 */
- (UIBarButtonItem *)indexButton;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method afterViewDidAppear:
 @discussion viewが表示された後の別Threaで起動される追加の表示処理.
 thumbnailの表示処理を行う.
 */
- (void) afterViewDidAppear:(id)arg;

/*!
 @method requireStoppingToAddThumbnails
 @discussion thumbnail処理を中断させる,中断されるまでLockされる
 */
- (void) stopToAddThumbnails;




@end
