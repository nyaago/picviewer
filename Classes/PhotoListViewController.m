//
//  PhotoListViewController.m
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

#import "PhotoListViewController.h"
#import "PhotoViewController.h"
#import "ThumbImageView.h"
#import "Photo.h"
#import "Album.h"
#import "PageControlViewController.h"
#import "AlbumInfoViewController.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

#define kDownloadMaxAtSameTime 5



@interface  PhotoListViewController (Private)

// 写真なしのメッセージタイプ - No Photos（写真がありません）
#define kNoPhotoMessage 1
// 写真なしのメッセージタイプ - Loding（写真を読み込み中です）
#define kLodingPhotosMessage 2

/*!
 @method downloadThumbnail:withPhotoModel
 @discussion photoのThumbnailをダウンロードする.
 @param photo Googleから取得したPhoto情報
 @param model ローカルDB上のPhotoのModelデータ
 @return 正常であれば、更新したModelObject, エラーであればnil
 */
- (void) downloadThumbnail:(GDataEntryPhoto *)photo withPhotoModel:(Photo *)model;

/*!
 @method addImageView:
 @discussion ImageView(thumbnail)をView階層へ追加する
 この処理は、Thread切り替えして起動する(
 performSelectorOnMainThread:withObject:waitUntilDone: で)
 必要があるため、メソッドとして定義。
 @param view 階層に追加されるview
 */
- (void)addImageView:(id)view;

/*!
 @method setNoPhotoMessage:
 @discussion No Phtos のメッセージ表示
 @param show 0/kNoPhotoMessage/kLodingPhotosMessage -> 表示/No Photos/Loging Photos
 */
- (void)setNoPhotoMessage:(NSNumber *)show;

/*!
 @method setContentSizeWithImageCount: 
 @discussion scrollViewのコンテンツサイズを設定.
 この処理は、Thread切り替えして起動する(
 performSelectorOnMainThread:withObject:waitUntilDone: で)
 必要があるため、メソッドとして定義。
 @param n scrollViewに表示されるImageView(thumbnail)の数(NSNumber *)
 */
- (void)setContentSizeWithImageCount;

/*!
 @method refreshAction:
 @discussion albumのリフレッシュ、全写真データを削除してから再ロードを行う.
 */
- (void) refreshAction:(id)sender;

/*!
 @method infoAction:
 @discussion Infoボタンのアクション、Album情報のViewを表示
 */
- (void) infoAction:(id)sender;


/*!
 @method refreshPhotos
 @discussion Photoデータを1回削除後、再ロード(Picasaへの問い合わせ+Thumbnail - download)
 */
- (void) refreshPhotos;


/*!
 @method enableToolbar:
 @discussion toolbarのButtonの有効無効の切り替え
 */
- (void) enableToolbar:(BOOL)enable;

/*!
 @method daysBetween:and:
 @discussion 日付オブジェクトの時間差を返す.
 */
- (NSInteger)minutesBetween:(NSDate *)d1 and:(NSDate *)d2;


/*!
 @method mustLoad
 @discussion データロードを行うかどうかの判定
 */
- (BOOL)mustLoad:(Album *)curAlbum;

/*!
 @method mustRefresh
 @discussion データの全ロードを行うがどうかの判定
 */
- (BOOL)mustRefresh:(Album *)curAlbum;

/*!
 @method loadPhotos
 @discussion 選択されている写真データのロード
 */
- (BOOL) loadPhotos:(Album *)curAlbum;

/*!
 @method removeProgressView
 @discussiom Progress Bar をView階層から削除（破棄はしない）
 */
- (void) removeProgressView;

/*!
 @method progressView
 @discussion Progress Bar View を返す
 */
- (LabeledProgressView *)progressView;

/*!
 @method downloadCompleted
 @discussion サムネイル画像がダウンロードされた後の処理。UI部品の状態変更。サムネイルのViewの追加。
              Main(UI)スレッドで実行させる。
 */
- (void) downloadCompleted;

/*!
 @method downloadCanceled
 @discussion サムネイル画像ダウンロードがキャンセルされた後の処理。UI部品の状態変更。
 Main(UI)スレッドで実行させる。
 */
- (void) downloadCanceled;


/*!
 @method discardTumbnail:
 @discussion サムネイルViewの削除
 */
- (void)discardTumbnail:(UIView *)view;

@end




@implementation PhotoListViewController

@synthesize managedObjectContext;
@synthesize album;
@synthesize scrollView;
@synthesize progressView;

#pragma mark View lifecycle


/*!
 @method loadView
 @discussion viewをload,scrollViewの設定とthumbnailのDictionaryの初期化処理を追加している
 */
- (void) loadView  {
  [super loadView];
  //
  isFromAlbumTableView = YES;
  // scrollView の設定
  self.scrollView.scrollEnabled = YES;
  self.scrollView.userInteractionEnabled = YES;
  self.scrollView.frame = self.view.bounds;
  self.scrollView.backgroundColor = [UIColor blackColor];
  self.scrollView.contentSize = CGSizeMake(720.0f, 100.0f);
  // toolbar
  self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.translucent = NO;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbarHidden = NO;

  thumbnailLock = [[NSLock alloc] init];
//  [self setToolbarItems: [self toolbarButtons] animated:YES];
}


/*!
 @method viewDidLoad:
 @discussion viewLoad時の通知,ロック変数,FetchedResultsControllerの初期化を行う.
 写真データが0件の場合は、Download処理を起動.
 */
- (void)viewDidLoad {
  NSLog(@"load did load");
  NSLog(@"photo view  viewDidLoad");
  self.navigationItem.backBarButtonItem.title = @"album0";

  [super viewDidLoad];
  if(self.album == nil) {
    return;
  }
  lockSave = [[NSLock alloc] init];

  [self loadPhotos:self.album];
  
  
  
  // Title設定
  self.navigationItem.title = self.album.title;
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
//  self.wantsFullScreenLayout = NO;
  // 戻る


}

/*!
 @method viewDidAppear:
 @discussion view表示時の通知
 thumbnailの表示処理を別threadで起動、全てのthumbnailのview階層への追加完了後にそれらが
 表示されるのではなく、view階層へ追加されるたびに表示されるようにするため.
 */
- (void) viewDidAppear:(BOOL)animated {
  NSLog(@"photo view  viewDidAppear");
  [super viewDidAppear:animated];
  
  // navigationbar,  statusbar
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
  /*
  self.navigationController.toolbarHidden = NO;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  **/
  // tool bar
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  // '写真がありませんメッセージ'表示
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kNoPhotoMessage]];

  if(self.album == nil) {
    return;
  }

  if(isFromAlbumTableView == NO) {	// 写真画面から戻ってきた場合
    // viewのサイズ, 前画面(写真)がtoolbar部分を含んでいたので、そのtoolbar分マイナス
    CGRect frame = self.view.frame;
    frame.size.height -= self.navigationController.toolbar.frame.size.height;
    self.view.frame = frame;
  }

  if(isFromAlbumTableView == YES) {
    [self setNoPhotoMessage:[NSNumber numberWithInteger:kLodingPhotosMessage]];
    // Thumbnailを表示するImageViewがview階層に追加されるたびにそれらが画面表示されるよう
    // (最後に一括して表示されるのではなく)、表示処理のloopを別Threadで起動、
    // ただし、実際のview階層への追加はこのmain Threadに戻って行われることになる(
    // 表示関連の操作はmain Threadでされる必要があるので)
    [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:) 
                             toTarget:self 
                           withObject:nil];
  }
}

- (void) afterViewDidAppear:(id)arg {
  
  //
  [self discardTumbnails];
  //
  [self loadThumbnails];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if([[UIDevice currentDevice] orientation] == layoutedOrientation) {
    return;
  }
  if([self shouldAutorotate]) {
    [ThumbImageView refreshAll];
  }
  layoutedOrientation = [[UIDevice currentDevice] orientation];
}


- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"didReceiveMemoryWarning");
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated {
  // 

}

- (void)viewDidDisappear:(BOOL)animated {
  // Google問い合わせ中の場合,停止を要求、完了するまで待つ
  if(picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
  
  // Download実行中の場合,停止を要求、完了するまで待つ
  /*
  if(downloader) {
    [downloader requireStopping];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
   */
  [self stopToAddThumbnails];
  isFromAlbumTableView = NO;
}

- (void)viewDidUnload {
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  /*
  NSLog(@"PhotoListViewController viewDidUnload ");
  NSLog(@"lockSave retain count = %d", [lockSave retainCount]);
  NSLog(@"backBUtton retain count = %d", [backButton retainCount]);
  NSLog(@"album retain count = %d", [album retainCount]);
  NSLog(@"managedObjectContext retain count = %d", [managedObjectContext retainCount]);
  NSLog(@"thumbnails count = %d", [thumbnails count]);
  NSLog(@"thumbnails retain count = %d", [thumbnails retainCount]);
  */
  [super viewDidUnload];
  [lockSave release];
  lockSave = nil;
  [thumbnailLock release];
  thumbnailLock = nil;

  /*
  if(downloader) {
    [downloader release];
    downloader = nil;
  }
   */
  [self discardTumbnails];
  
}

/*!
 機器回転時に自動的にView回転を行うかの判定.
 splitView内にある場合（iPad）は自動的に回転されるように、YESを返す。
 */
- (BOOL)shouldAutorotate {
  if([self splitViewController]) {
    return YES;
  }
  else {
    return NO;
  }
}

/*!
 サポートされている機器の向き
 splitView内にある場合(iPad）はすべて、層でない場合はPortraitのみ.
 */
- (NSUInteger)supportedInterfaceOrientations {
  if([self splitViewController]) {
    return UIInterfaceOrientationMaskAll;
  }
  else {
    return UIInterfaceOrientationMaskPortrait;
  }
}

/*!
 ios5まで用.
 splitView内にある場合(iPad）はすべて、層でない場合はPortraitのみ.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
  if([self splitViewController]) {
    return YES;
  }
  else {
    return NO;
  }
}


- (void)dealloc {
  NSLog(@"PhotoListViewController dealloc");
  if(progressView) {
    NSLog(@"progressView retain count = %d", [progressView retainCount]);
  }
  NSLog(@"backBUtton retain count = %d", [backButton retainCount]);
  NSLog(@"album retain count = %d", [album retainCount]);
  NSLog(@"managedObjectContext retain count = %d", [managedObjectContext retainCount]);
  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [picasaFetchController release];
    picasaFetchController = nil;
  }
  
  // ダウンロード中であれば、ダウンロード停止要求をして、停止するまで待つ
  /*
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [downloader release];
    downloader = nil;
  }
   */
  [self discardTumbnails];
  if(progressView)
    [progressView release];
  if(backButton)
    [backButton release];
  if(indexButton)
    [indexButton release];
  if(infoButton)
    [infoButton release];
  if(refreshButton)
    [refreshButton release];
  if(toolbarButtons)
    [toolbarButtons release];
  if(album)
    [album release];
  if(modelController)
    [modelController release];
  if(managedObjectContext)
    [managedObjectContext release];
  if(lockSave)
    [lockSave release];
  if(thumbnailLock)
    [thumbnailLock release];
  [super dealloc];
}

#pragma mark Method For performing on MainThread

- (void)addImageView:(id)imgView {
  UIView *v = (UIView *)imgView;
  [self.scrollView addSubview:v];
}

- (void)setContentSizeWithImageCount {
  
  CGPoint point = [ThumbImageView bottomRight];
  if(point.x == 0.0f && point.y == 0.0f) {
    self.scrollView.contentSize =  CGSizeMake(self.scrollView.frame.size.width,
                                              self.scrollView.frame.size.height);
  }
  else {
    self.scrollView.contentSize =  CGSizeMake(self.scrollView.frame.size.width,
                                              point.y + 0.0f);
  }
}

- (void)setNoPhotoMessage:(NSNumber *)show {
  
  
  if(noPhotoLabel == nil && [show boolValue] == YES) {
    CGRect frame = CGRectMake(0.0f, self.view.bounds.size.height / 3,
                              self.view.bounds.size.width, 30.0f);
    noPhotoLabel = [[UILabel alloc] initWithFrame:frame];
    noPhotoLabel.textAlignment = UITextAlignmentCenter;
    noPhotoLabel.opaque = NO;
    noPhotoLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    noPhotoLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize] * 1.5f];
    noPhotoLabel.textColor = [UIColor lightGrayColor];
  }
  if([show boolValue] == YES) {
    if([noPhotoLabel superview] == nil) {
      [self.scrollView addSubview:noPhotoLabel];
      NSLog(@"message type  = %d", [show integerValue] );
      noPhotoLabel.text = [show integerValue] == kLodingPhotosMessage ?
      NSLocalizedString(@"PhotoList.Loding", @"Loging Photos") :
      NSLocalizedString(@"PhotoList.None", @"No Photos");
    }
  }
  else {
    if(noPhotoLabel != nil && [noPhotoLabel superview] != nil) {
      [noPhotoLabel removeFromSuperview];
    }
  }
}

#pragma mark -

- (void)loadThumbnails {
  // このMethod は Main以外のThreadで実行される.
  // なのでUIに関する操作は、performSelectorOnMainThreadでMain Thread Queueへ移動させている。
  
  // thumbnailを保持するコレクションの準備
  [thumbnailLock lock];

  [onAddingThumbnailsLock lock];
  onAddingThumbnails = YES;
  stoppingToAddingThumbnailsRequred = NO;
  [onAddingThumbnailsLock unlock];
  
  [self.view setNeedsLayout];
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //NSDate *date0 = [[[NSDate alloc] init] autorelease];	  // for logging
  if([modelController photoCount] == 0) {
    [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                           withObject:[NSNumber numberWithInteger:kNoPhotoMessage]
                        waitUntilDone:NO];
  }
  else {
    [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                           withObject:[NSNumber numberWithBool:NO]
                        waitUntilDone:NO];
    for(NSUInteger i = 0; i < [modelController photoCount]; ++i) {
      UIView *imageView = [self thumbnailAt:i];
      // ImageViewのView階層への追加を行う(main threadで行う必要がある)
      if(imageView) {
        [self performSelectorOnMainThread:@selector(addImageView:)
                               withObject:imageView 
                            waitUntilDone:NO];
      }
      // 中断が要求されているかチェック
      [onAddingThumbnailsLock lock];
      if(stoppingToAddingThumbnailsRequred) {
        [onAddingThumbnailsLock unlock];
        break;
      }
      [onAddingThumbnailsLock unlock];
      
    }
  }
  // scrollViewのcontent sizeを設定(main threadで行う必要がある)
  [self performSelectorOnMainThread:@selector(setContentSizeWithImageCount)
                         withObject:nil
                      waitUntilDone:YES];
  [onAddingThumbnailsLock lock];
  onAddingThumbnails = NO;
  stoppingToAddingThumbnailsRequred = NO;
  [onAddingThumbnailsLock unlock];
  [thumbnailLock unlock];
  [pool drain];
}

- (void) stopToAddThumbnails {
  [onAddingThumbnailsLock lock];
  stoppingToAddingThumbnailsRequred = YES;
  [onAddingThumbnailsLock unlock];
  while (YES) {
    [onAddingThumbnailsLock lock];
    if(onAddingThumbnails == NO) {
      [onAddingThumbnailsLock unlock];
      break;
    }
    [onAddingThumbnailsLock unlock];
  }
  return;
}


- (void)discardTumbnails {
  
  [thumbnailLock lock];
  [ThumbImageView cleanup];
  [thumbnailLock unlock];
  
}

- (void)discardTumbnail:(UIView *)view {
  if([view superview]) {
    
    [view removeFromSuperview];
  }
  [view release];
}


- (UIView *)thumbnailAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  ThumbImageView *imageView = nil;
  NSUInteger indexes[2];
  indexes[0] = 0;
  // 画像データを取得してUIImageViewを生成
  indexes[1] = index;
  Photo *photoObject = [modelController photoAt:index];
  UIImage *image = nil;
  if(photoObject.thumbnail) {
    image  = [UIImage imageWithData:photoObject.thumbnail];
    imageView = [ThumbImageView viewWithImage:image
                                    withIndex:[NSNumber numberWithInt:index]
                                withContainer:self.view ];
    imageView.userInteractionEnabled = YES;
    imageView.delegate = self;
  }
  
  [pool drain];
  return imageView;
}


- (NSArray *) toolbarButtons {
  NSString *path;
  if(!toolbarButtons) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    toolbarButtons = [[NSMutableArray alloc] init];
    
    // Refresh
    refreshButton = [[UIBarButtonItem alloc] 
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                     target:self
                     action:@selector(refreshAction:)];
    [toolbarButtons addObject:refreshButton];
    
    // Space
    UIBarButtonItem *spaceRight = [[UIBarButtonItem alloc] 
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                   target:self
                                   action:nil];
    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];
    
    // Info
    infoButton = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                  style:UIBarButtonItemStyleBordered 
                                                 target:self
                                                 action:@selector(infoAction:)];
    path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    infoButton.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:infoButton];
    
    [pool drain];
  }
  return toolbarButtons;
}



#pragma mark -

#pragma mark AlbumTableViewControllerDelegate

- (void) albumTableViewControll:(AlbumTableViewController *)controller
                    selectAlbum:(Album *)selectedAlbum {
  // '写真がありませんメッセージ'表示
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kLodingPhotosMessage]];
  
  isFromAlbumTableView = YES;
  [self discardTumbnails];
  if(downloader != nil && ![downloader isCompleted] && [downloader isStarted]) {
    [modelController clearLastAdd];
    [downloader requireStopping];
  }

  self.album = selectedAlbum;
  // Title設定
  self.navigationItem.title = self.album.title;
  BOOL load = [self loadPhotos:self.album];
//  [self loadThumbnails];
  // navigationbar,  statusbar
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
  // tool bar
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  
  if(self.album == nil) {
    return;
  }
  
  if(isFromAlbumTableView == NO) {	// 写真画面から戻ってきた場合
    // viewのサイズ, 前画面(写真)がtoolbar部分を含んでいたので、そのtoolbar分マイナス
    CGRect frame = self.view.frame;
    frame.size.height -= self.navigationController.toolbar.frame.size.height;
    self.view.frame = frame;
  }
  
  if( load == NO) {
    // Thumbnailを表示するImageViewがview階層に追加されるたびにそれらが画面表示されるよう
    // (最後に一括して表示されるのではなく)、表示処理のloopを別Threadで起動、
    // ただし、実際のview階層への追加はこのmain Threadに戻って行われることになる(
    // 表示関連の操作はmain Threadでされる必要があるので)
    [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:)
                             toTarget:self
                           withObject:nil];
  }
  self.view.userInteractionEnabled = YES;
  
}


#pragma mark -

#pragma mark PicasaFetchControllerDelegate

// Googleへの問い合わせの応答の通知
// ローカルDBへの登録を行う.
- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL hasErrorInInserting = NO;
  if(error) {
    // Error
    NSString *title = NSLocalizedString(@"Error","Error");
    NSString *message = NSLocalizedString(@"Error.ConnectionToServer","Error");
    if ([error code] == 404) {   // ユーザがいない
      title = NSLocalizedString(@"Result",@"Result");
      message = NSLocalizedString(@"Warn.NoAlbum", @"No album");
    }
    //	NSLog(@" error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:title
                              message:message
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [pool drain];
    return;
  }
  // clean fetched controller
  //[fetchedPhotosController release];
  //fetchedPhotosController = nil;
  // 削除
  if(onRefresh) {
	  [modelController removePhotos];
  }
  
  // ローカルDBへの保存
  NSArray *entries = [feed entries];
  if ([entries count] > 0) {
    NSLog(@"the album has %d photos", [[feed entries] count]);
    for (int i = 0; i < [entries count]; ++i) {
      GDataEntryPhoto *photo = [entries objectAtIndex:i];
      NSLog(@"photo - title = %@, ident=%@, feedlink=%@",
            [[photo title] contentStringValue], [photo GPhotoID], [photo feedLink]);
      //  [self queryPhotoAlbum:[album GPhotoID] user:[album username]];
      BOOL f;
      if(onRefresh || ![modelController selectPhoto:photo hasError:&f] ) {
        if([progressView subviews] != nil) {
          // toolbarのButtonを無効に
          [self enableToolbar:NO];
					// progress 状態表示
          [self.view addSubview:progressView];
        }
        Photo *photoModel =  [modelController insertPhoto:photo withAlbum:album];
        if(photoModel) {
          [self downloadThumbnail:photo withPhotoModel:photoModel];
        }
        else {
          hasErrorInInserting = YES;
        }
      }
    }
  }	
  // Photo一覧のFetched Controllerを生成
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  if (![modelController.fetchedPhotosController performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error","Error")
                              message:NSLocalizedString(@"Error.Fetch", 
                                                        @"Error IN Saving")
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [pool drain];
    return;
  }
  if(hasErrorInInserting) {
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error", @"Error")
                              message:NSLocalizedString(@"Error.Insert", 
                                                        @"Error IN Saving")
                              delegate:self 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadThumb",
                                             @"download")];
  if([modelController photoCount] == 0) {
    progressView.progress = 1.0f;
  }
  else {
    progressView.progress = 1.0f / [modelController photoCount];
    [progressView setNeedsLayout];
  }
  [downloader start];
  [downloader finishQueuing];
  [pool drain];
  [picasaFetchController release];
  picasaFetchController = nil;
  onRefresh = NO;
}


// Googleへの問い合わせの結果、認証エラーとなった場合の通知
- (void) PicasaFetchWasAuthError:(NSError *)error {
  NSLog(@"auth error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"Error","Error");
  NSString *message = NSLocalizedString(@"Error.Auth","AUTH ERROR");
  UIAlertView *alertView = [[UIAlertView alloc] 
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK" 
                            otherButtonTitles:nil];
  [alertView show];
  [alertView release];
  [pool drain];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  //
  [self removeProgressView];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
}

// Googleへの問い合わせの結果、指定ユーザがなかった場合の通知
- (void) PicasaFetchNoUser:(NSError *)error {
  NSLog(@"no user");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"WARN","WARN");
  NSString *message = NSLocalizedString(@"Warn.NoUser","NO USER");
  UIAlertView *alertView = [[UIAlertView alloc] 
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK" 
                            otherButtonTitles:nil];
  [alertView show];
  [alertView release];
  [pool drain];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  //
  [self removeProgressView];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
}

// Googleへの問い合わせの結果、エラーとなった場合の通知
- (void) PicasaFetchWasError:(NSError *)error {
  NSLog(@"connection error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"Error","Error");
  NSString *message = NSLocalizedString(@"Error.ConnectionToServer",
                                        "Connection ERROR");
  UIAlertView *alertView = [[UIAlertView alloc] 
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK" 
                            otherButtonTitles:nil];
  [alertView show];
  [alertView release];
  [pool drain];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  //
  [self removeProgressView];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
}



#pragma mark -

#pragma mark ThumbImageViewDelegate

- (void)photoTouchesEnded:(ThumbImageView *)imageView
                  touches:(NSSet *)touches
                withEvent:(UIEvent *)event {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // 写真表示Viewへ
  NSInteger index = [imageView.index integerValue];
  if(index >= 0 && index < [modelController photoCount]) {
    PageControlViewController *pageController =
    [[[PageControlViewController alloc] init] autorelease];
    
    NSLog(@"init PageControllerView retain count = %d",[pageController retainCount]);
    pageController.source = self;
    pageController.curPageNumber = index;
    NSLog(@"begore push PageControllerView retain count = %d",[pageController retainCount]);
    if([self splitViewController]) {
      UINavigationController *navController = [[[UINavigationController alloc]
                                                initWithRootViewController:pageController]
                                               autorelease];
      [[navController navigationBar] setHidden:NO];
      [self.splitViewController presentViewController:navController
                                             animated:YES
                                           completion:^{
                                             
                                           }];
    }
    else {
      self.navigationItem.backBarButtonItem = [PhotoViewController backButton];
      [self.navigationController pushViewController:pageController animated:YES];
    }
    NSLog(@"push PageControllerView retain count = %d",[pageController retainCount]);
    [pool drain];
  }


}



#pragma mark -

#pragma mark Touch

/*
 touch終了
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  // Scroll 操作から手を果たした場合は、scrollView の既定の動作
  if(onScroll == YES) {
    onScroll = NO;
    return;
  }
  // Thumbnail のViewタッチの場合
  UITouch *touch = [touches anyObject];
  ThumbImageView *touchView = [ThumbImageView findByPoint:[touch locationInView:self.scrollView]];
  if(touchView != nil) {
    [touchView touchesEnded:touches withEvent:event];
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  onScroll = NO;
  [super touchesBegan:touches withEvent:event];
 // [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  onScroll = YES;
  [super touchesMoved:touches withEvent:event];
  //[[self nextResponder] touchesMoved:touches withEvent:event];
}


#pragma mark Private



- (void) downloadThumbnail:(GDataEntryPhoto *)photo withPhotoModel:(Photo *)model {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if([[[photo mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[photo mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    NSString *urlForThumbnail = [thumbnail URLString];
    NSDictionary *dict = [[NSDictionary alloc]
                          initWithObjectsAndKeys:model, @"photo", nil] ;
    [downloader addURL:[NSURL URLWithString:urlForThumbnail ]
          withUserInfo:dict];
    [dict release];
  }
  [pool drain];
}


- (UIBarButtonItem *)backButton {
  if(!backButton) {
    backButton = [[UIBarButtonItem alloc] 
                  initWithTitle:NSLocalizedString(@"Albums", @"Albums")
                  style:UIBarButtonItemStyleDone 
                  target:nil
                  action:nil ];
    
  }
  return backButton;
}

- (UIBarButtonItem *)indexButton {
 if(!indexButton) {
   indexButton = [[UIBarButtonItem alloc]
                 initWithTitle:NSLocalizedString(@"Albums", @"Albums")
                 style:UIBarButtonItemStyleDone
                 target:nil
                 action:nil ];
   
 }
 return indexButton;
}

- (void) refreshPhotos {

  onRefresh = YES;
  hasErrorInDownloading = NO;
  hasErrorInInsertingThumbnail = NO;
  //
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //  NSArray *objects = [fetchedPhotosController fetchedObjects];
  // toolbarのButtonを無効に
  [self enableToolbar:NO];
  // 再ロード
  SettingsManager *settings = [[SettingsManager alloc] init];
  picasaFetchController = [[PicasaFetchController alloc] init];
  picasaFetchController.delegate = self;
  picasaFetchController.userId = settings.userId;
  picasaFetchController.password = settings.password;
  [self.view addSubview:[self progressView]];
  [picasaFetchController queryAlbumAndPhotos:self.album.albumId 
                                        user:[self.album.user valueForKey:@"userId"]
                               withPhotoSize:[NSNumber numberWithInt:settings.imageSize]
                               withThumbSize:[NSNumber numberWithInteger:
                                              [ThumbImageView thumbWidthForContainer:self.view] *
                                              [[UIScreen mainScreen] scale]]];
  downloader = [[QueuedURLDownloader alloc]
                initWithMaxAtSameTime:kDownloadMaxAtSameTime];
  downloader.delegate = self;
  [settings release];
  [pool drain];
  
}

- (void) enableToolbar:(BOOL)enable {
  refreshButton.enabled = enable;
  infoButton.enabled = enable;
}

- (NSInteger)minutesBetween:(NSDate *)d1 and:(NSDate *)d2 {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if(!d1) {
    d1 = [NSDate date];
  }
  if(!d2) {
    d2 = [NSDate date];
  }
  NSTimeInterval t  = [d2 timeIntervalSinceDate:d1];
  NSInteger n = (NSInteger)(t  / 60);
  [pool drain];
  return n;
}

- (BOOL) mustLoad:(Album *)curAlbum {
  if(isFromAlbumTableView == NO)
    return NO;
  if([modelController album].albumId != curAlbum.albumId) {
    return YES;
  }
  if([modelController photoCount] == 0) {
    // Network接続確認
    if(![NetworkReachability reachable]) {
      NSString *title = NSLocalizedString(@"Notice","Notice");
      NSString *message = NSLocalizedString(@"Warn.NetworkNotReachable",
                                            "not reacable");
      UIAlertView *alertView = [[UIAlertView alloc] 
                                initWithTitle:title
                                message:message
                                delegate:nil
                                cancelButtonTitle:@"OK" 
                                otherButtonTitles:nil];
      [alertView show];
      [alertView release];
      return NO;
    }
    onRefresh = YES;
		return YES;
  }
    
  if ( ( curAlbum.lastAddPhotoAt == nil ||
        [self minutesBetween:curAlbum.lastAddPhotoAt and:[NSDate date] ] > 15)
        &&
      [NetworkReachability reachableByWifi]) {
    return YES;
  }
  return NO;
}

- (BOOL)mustRefresh:(Album *)curAlbum {
  if([modelController album].albumId != curAlbum.albumId) {
    return YES;
  }
  if([modelController photoCount] == 0) {
    return YES;
  }
  if(curAlbum != nil && [curAlbum lastAddPhotoAt] == nil) {
    return YES;
  }
  return NO;
}


- (BOOL) loadPhotos:(Album *)curAlbum {
  
  downloader = [[QueuedURLDownloader alloc]
                initWithMaxAtSameTime:kDownloadMaxAtSameTime];
  downloader.delegate = self;

  modelController = [[PhotoModelController alloc]
                     initWithContext:self.managedObjectContext
                     withAlbum:curAlbum];
  modelController.managedObjectContext = self.managedObjectContext;
  
  NSLog(@"fetchedPhotosController");
  NSError *error = nil;
  if (![[modelController fetchedPhotosController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Error",@"Error")
                              message:NSLocalizedString(@"Error.Fetch", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    return NO;
  }
  NSLog(@"fetchedPhotosController completed");
  // Photoが0件であれば、Googleへの問い合わせを起動.
  // 問い合わせ結果は、albumAndPhotoWithTicket:finishedWithUserFeed:errorで受け
  // CoreDataへの登録を行う
  BOOL ret = NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if([self mustLoad:curAlbum]) {
    // クリア + 全ロードか?
    onRefresh = [self mustRefresh:curAlbum];
    
    // toolbarのButtonを無効に
    [self enableToolbar:NO];
    self.scrollView.userInteractionEnabled = NO;
    // progress View
    progressView.progress = 0.0f;
    [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                               @"download")];
    if(onRefresh) {
      [self.view addSubview:[self progressView]];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    //
    SettingsManager *settings = [[SettingsManager alloc] init];
    picasaFetchController = [[PicasaFetchController alloc] init];
    picasaFetchController.delegate = self;
    picasaFetchController.userId = settings.userId;
    picasaFetchController.password = settings.password;
    [picasaFetchController queryAlbumAndPhotos:curAlbum.albumId
                                          user:[curAlbum.user valueForKey:@"userId"]
                                 withPhotoSize:[NSNumber numberWithInt:settings.imageSize]
                                 withThumbSize:[NSNumber numberWithInteger:
                                               [ThumbImageView thumbWidthForContainer:self.view] *
                                                [[UIScreen mainScreen] scale]]];
    [settings release];
    ret = YES;
  }
  [pool drain];
  return ret;
}

- (LabeledProgressView *)progressView {
  if(progressView) {
    return progressView;
  }
  // progressView
  CGRect frame = CGRectMake(0.0f, self.view.frame.size.height - 200.0f ,
                            self.view.frame.size.width, 200.0f);
  progressView = [[LabeledProgressView alloc] initWithFrame:frame];
  [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                      @"download")];

  return progressView;
}

- (void) removeProgressView {
  [progressView removeFromSuperview];
  [progressView release];
  progressView = nil;
}


/*!
 すべてダウンロード完了時の通知
 */
- (void)downloadCompleted {
  // 表示をリフレッシュ
  NSLog(@"downloadCompleted");
  //  [(UITableView *)self.view reloadData];
  if(hasErrorInDownloading) {  // Thumbnail ダウンロードエラーがある場合.
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Error", @"Error")
                              message:NSLocalizedString(@"Error.DownloadThumb",
                                                        @"Error IN Downloading")
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  if(hasErrorInInsertingThumbnail) {  // Thumbnail 登録エラーがある場合.
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Error", @"Error")
                              message:NSLocalizedString(@"Error.InsertThumb",
                                                        @"Error IN Saving")
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  // albumのphotoに対する最後の保存処理実行日時を記録
  NSLog(@"downloadCompleted - set last add");
  [modelController setLastAdd];
  //
  NSLog(@"downloadCompleted - remove progress");
  [self removeProgressView];

  // toolbarのボタンを有効に
  NSLog(@"downloadCompleted - enable tool bar");
  [self enableToolbar:YES];
  //
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   //
  NSLog(@"downloadCompleted - afterViewDidAppear");
  [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:)
                           toTarget:self
                         withObject:nil];
  self.view.userInteractionEnabled = YES;
  self.scrollView.scrollEnabled = YES;
  self.scrollView.userInteractionEnabled = YES;
}

/*!
 ダウンロードキャンセル時の通知
 */
- (void)downloadCanceled {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  //
  [self removeProgressView];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
  self.view.userInteractionEnabled = YES;
  self.scrollView.scrollEnabled = YES;
  self.scrollView.userInteractionEnabled = YES;

}


#pragma mark - 

#pragma mark QueuedURLDownloaderDelegate

- (void)didReceiveData:(NSData *)data withUserInfo:(NSDictionary *)info {
  NSLog(@"didReceiveData");
}

/*!
 ダウンロードエラー時の通知
 */
- (void)downloadDidFailWithError:(NSError *)error 
                    withUserInfo:(NSDictionary *)info {
  NSLog(@"downloadDidFailWithError");
  hasErrorInDownloading = YES;
  progressView.progress = progressView.progress + (1.0 / [modelController photoCount] );
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  Photo *photo = (Photo *)[info objectForKey:@"photo"];
  if(photo) {
    if( [modelController updateThumbnail:data forPhoto:photo] == nil) {
      hasErrorInInsertingThumbnail = YES;
    }
  }
  NSNumber *f = [NSNumber numberWithFloat:progressView.progress + 
                 (1.0f / [modelController photoCount]) ];
  [self performSelectorOnMainThread:@selector(updateProgress:) 
                         withObject:f
                      waitUntilDone:NO];
//  progressView.progress = progressView.progress + 
//  (1.0 / [self thumbnailCount] );
}

- (void) updateProgress:(NSNumber *)v {
  NSLog(@"progress - %f", [v floatValue]);
  progressView.progress = [v floatValue];
  [progressView setNeedsLayout];
}

/*!
 すべてダウンロード完了時の通知
 */
- (void)didAllCompleted:(QueuedURLDownloader *)urlDownloader {
  // 表示をリフレッシュ
  //  [(UITableView *)self.view reloadData];
  [urlDownloader release];
  urlDownloader = nil;
  downloader = nil;
  //
  [self performSelectorOnMainThread:@selector(downloadCompleted)
                         withObject:nil
                      waitUntilDone:YES];

}

/*!
 ダウンロードキャンセル時の通知
 */
- (void)dowloadCanceled:(QueuedURLDownloader *)urlDownloader {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [urlDownloader release];
  urlDownloader = nil;
  downloader = nil;
  //
  [self performSelectorOnMainThread:@selector(downloadCanceled)
                         withObject:nil
                      waitUntilDone:YES];

}



#pragma mark Action

- (void) refreshAction:(id)sender {
  if(![NetworkReachability reachable]) {
    NSString *title = NSLocalizedString(@"Notice","Notice");
    NSString *message = NSLocalizedString(@"Notice.NetworkNotReachable",
                                          "not reacable");
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:title
                              message:message
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok")
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    return;
  }
  // Network接続確認
  if(![NetworkReachability reachableByWifi]) {
    NSString *title = NSLocalizedString(@"Notice","Notice");
    NSString *message = NSLocalizedString(@"Notice.WifiNotReachable",
                                          "only 3G");
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:title
                              message:message
                              delegate:self
                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                              otherButtonTitles:NSLocalizedString(@"Continue", @"Continue"),
                              nil];
    [alertView show];
    [alertView release];
    return;
  }
  progressView.progress = 0.0f;
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kLodingPhotosMessage]];
  [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                             @"download")];
  [self discardTumbnails];
  [self.view addSubview:progressView];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self performSelectorOnMainThread:@selector(refreshPhotos) 
                         withObject:nil 
                      waitUntilDone:NO];
  
  
} 

- (void) infoAction:(id)sender {
  
  AlbumInfoViewController *viewController = [[AlbumInfoViewController alloc]
                                             initWithNibName:@"AlbumInfoViewController" 
                                             bundle:nil];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  
  viewController.album = self.album;
  [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
  [[self parentViewController] presentModalViewController:navigationController 
                                                 animated:YES];
	[viewController release];
  [navigationController release];
}

#pragma mark -

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if(alertView.cancelButtonIndex == buttonIndex) {
  }
  else {	// データダウンロード処理を実行
    progressView.progress = 0.0f;
    [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                               @"download")];
    [self discardTumbnails];
    [self.view addSubview:progressView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorOnMainThread:@selector(refreshPhotos) 
                           withObject:nil 
                        waitUntilDone:NO];
    
  }
}

#pragma mark -
#pragma mark UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc {
  barButtonItem.title = NSLocalizedString(@"Album", @"Album");
  
  [[self navigationItem] setLeftBarButtonItem:barButtonItem];
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
  
  if(barButtonItem == [[self navigationItem] leftBarButtonItem]) {
    barButtonItem.title = nil;
    [[self navigationItem] setLeftBarButtonItem:nil];
  }
}


#pragma mark -

#pragma mark DeviceRotationDelegate

-(void) deviceRotated:(UIDeviceOrientation)orient {
  NSLog(@"device ROtated");
  // 回転処理中は、表示位置がずれないようにtoolbarを非表示にする、最後に現在の状態(表示/非表示)に戻す
  if(layoutedOrientation == [[UIDevice currentDevice]orientation] ) {
    return;
  }
}


#pragma mark -

- (NSUInteger) pageCount {
  return [modelController photoCount];
  
}

- (UIViewController<PageViewDelegate> *) pageAt:(NSUInteger)n {
  PhotoViewController *viewController = [[PhotoViewController alloc] 
                                         initWithNibName:@"PhotoViewController" 
                                         bundle:nil];
  viewController.fetchedPhotosController = modelController.fetchedPhotosController;
  viewController.managedObjectContext = self.managedObjectContext;
  viewController.indexForPhoto = n;
  return viewController;
}



@end
