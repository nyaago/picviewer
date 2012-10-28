//
//  PhotoListViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PicasaFetchController.h"
#import "QueuedURLDownloader.h"
#import "PageControlViewController.h"
#import "AlbumTableViewController.h"
#import "AlbumTableViewControllerDelegate.h"
#import "Album.h"
#import "Photo.h"
#import "PhotoModelController.h"
#import "LabeledProgressView.h"

@interface PhotoListViewController : UIViewController
<PicasaFetchControllerDelegate, 
QueuedURLDownloaderDelegate, PageControlViewControllerDataSource,
UIAlertViewDelegate,UISplitViewControllerDelegate,AlbumTableViewControllerDelegate> {
  
  @private
  
  Album *album;
  
  NSManagedObjectContext *managedObjectContext;
  
  PhotoModelController *modelController;
  QueuedURLDownloader *downloader;
  
  UIBarButtonItem *backButton;
  UIScrollView *scrollView;
  LabeledProgressView *progressView;
  // ローカルDB保存時の Lock Object
  NSLock  *lockSave;
  // Download中にエラーが発生したか?
  BOOL hasErrorInDownloading;
  // Thumbnailの登録中にエラーが発生したか?
  BOOL hasErrorInInsertingThumbnail;
  // thumbnailコレクション
  NSMutableDictionary *thumbnails;
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
 @method discardTumbnailAt:
 @discussion 指定したインデックスのThumbnailの破棄
 @param index 0起点のindex
 */
- (void)discardTumbnailAt:(NSUInteger)index;

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
