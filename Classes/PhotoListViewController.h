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
#import "LabeledActivityIndicator.h"

@interface PhotoListViewController : UIViewController
<PicasaFetchControllerDelegate, 
QueuedURLDownloaderDelegate, PageControlViewControllerDataSource,
UIAlertViewDelegate,UISplitViewControllerDelegate,AlbumTableViewControllerDelegate,
ThumbImageViewDelegate, UIActionSheetDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate> {
  
  @private
  // CoreData user model
  User *user;
  // CoreData album Model
  Album *album;
  // 次に表示することを指定されたCoreData album Model
  Album *nextShowedAlbum;
  // 表示しようとしているAlbum
  Album *showingAlbum;
  //
  NSManagedObjectContext *managedObjectContext;
  // CoreData Model のController
  PhotoModelController *modelController;
  // PhotoのDownloader
  QueuedURLDownloader *downloader;
  // Navigation bar の back button
  UIBarButtonItem *backButton;
  UIScrollView *scrollView;
  LabeledProgressView *progressView;
  LabeledActivityIndicator *activityIndicatorView;
  // ローカルDB保存時の Lock Object
  NSLock  *lockSave;
  // Download中にエラーが発生したか?
  BOOL hasErrorInDownloading;
  // Thumbnailの登録中にエラーが発生したか?
  BOOL hasErrorInInsertingThumbnail;
  // スクロール中フラグ
  BOOL onScroll;
  // Thumbnail表示処理中にOnになるフラグ
  BOOL onAddingThumbnails;
  // Thumbnail表示中フラグの同期変数
  NSLock *onAddingThumbnailsLock;
  // Thumbnail表示処理の中断が要求されている?
  BOOL stoppingToAddingThumbnailsRequired;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;
  // Picasaデータ取得コントローラー
  PicasaFetchController *picasaFetchController;
  // refresh Button
  UIBarButtonItem *refreshButton;
  // view information Button
  UIBarButtonItem *infoButton;
  // view photo Button
  UIBarButtonItem *photoButton;
  // サムネイルloadが必要か
  BOOL needToLoad;
  // サムネイル処理のLock
  NSLock *thumbnailLock;
  // 現在layoutされている向き
  UIDeviceOrientation layoutedOrientation;
  //
  UILabel *noPhotoLabel;

  UIPopoverController *pickerPopoverController;
  // picasa の サーバーへの更新を行ったあと全リロードを行うか？
  BOOL refreshAfterPicasaUpdated;
  // 最後に撮影して（サーバーに保存されていない）写真
  UIImage *lastTakenPhoto;
}

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*!
 @property user
 @discussion 現在選択されているuser
 */
@property (nonatomic, retain) User *user;

/*!
 @property album
 @discussion 現在選択されているalbum
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
 @property activeIndicatorView
 @discussion ダウンロード処理中に表示するindicator のView
 */
@property (nonatomic, retain) IBOutlet LabeledActivityIndicator *activityIndicatorView;


/*!
 @property picasaFetchController
 @discussion
 */
@property (nonatomic, retain) PicasaFetchController *picasaFetchController;

/*!
 @proprtyu needToLoad
 @discussion サムネイルloadが必要か
 */
@property (nonatomic) BOOL needToLoad;

/*!
 @property lastTakenPhoto
 @discussion 最後に撮影して（サーバーに保存されていない）写真
 */
@property (nonatomic, retain) UIImage *lastTakenPhoto;

@property (nonatomic, retain) QueuedURLDownloader *downloader;

/*!
 @method setAlbum:
 @param album
 */
- (void) setAlbum:(Album *)album;

/*!
 @method setUser:
 @param user 
 */
- (void) setUser:(User *)user;

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
 @discussion Navigation bar の 戻るボタン返す
 */
- (UIBarButtonItem *)backButton;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method afterViewDidAppear:
 @discussion viewが表示された後の別Threadで起動される追加の表示処理.
 thumbnailの表示処理を行う.
 */
- (void) afterViewDidAppear:(id)arg;

/*!
 @method requireStoppingToAddThumbnails
 @discussion thumbnail処理を中断させる,中断されるまでLockされる
 */
- (void) stopToAddThumbnails;

/*!
 @method refreshPhotos
 @param refreshAll １回全クリアするか？
 @discussion Photoデータを1回削除後、再ロード(Picasaへの問い合わせ+Thumbnail - download)
 */
- (void) refreshPhotos:(BOOL)refreshAll;


/*!
 */
- (PicasaFetchController *) picasaFetchController;

@end
