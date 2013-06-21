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
#define kLoadingPhotosMessage 2
// アルバム未選択のメッセージタイプ - Choose a albumu（アルバムを選択してください）
#define kChooseAlbumMessage 3
// Album の Reload確認を行う間隔（分）
#define kIntervalForReload 15

/*!
 @method canUpdatePhotos
 @return photo に対する更新操作が可能か？
 */
- (BOOL) canUpdatePhotos;
/*!
 @method addTbumbnailForPhoto:
 @param photo photo モデル
 @discussion 指定した写真モデルについてサムネイルをview上に表示する。
 */
- (void) addTbumbnailForPhoto:(Photo *)photo;

/*!
 @method refreshAction:
 @discussion albumのリフレッシュ、全写真データを削除してから再ロードを行う.
 */
- (void) refreshAction:(id)sender;

/*!
 @method photoAction:
 @discussion photo撮影/選択
 */
- (void) photoAction:(id)sender;

/*!
 @method infoAction:
 @discussion Infoボタンのアクション、Album情報のViewを表示
 */
- (void) infoAction:(id)sender;

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
 @method enableToolbar:
 @discussion toolbarのButtonの有効無効の切り替え
 */
- (void) enableToolbar:(BOOL)enable;

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
 @param show 0/kNoPhotoMessage/kLoadingPhotosMessage/kChooseAlubum 
 -> 表示/No Photos/Loging Photos/ChooseAlbumu
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
 @method loadPhotos
 @discussion 選択されている写真データのロード
 */
- (BOOL) loadPhotos:(Album *)curAlbum;

/*!
 @metohd photoModelController
 @discussion photo model 検索のcontrollerを返す
 */
- (PhotoModelController *) photoModelController;

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

/*!
 @method onAlbumSelected:
 @discussion Album を反映する。
 */
- (void) onAlbumSelected:(Album *)album;

@end




@implementation PhotoListViewController

@synthesize managedObjectContext;
@synthesize album;
@synthesize scrollView;
@synthesize progressView;

#pragma mark View lifecycle


/*!
 @method  iew
 @discussion viewをload,scrollViewの設定とthumbnailのDictionaryの初期化処理を追加している
 */
- (void) loadView  {
  [super loadView];
}

/*!
 @method viewDidLoad:
 @discussion viewLoad時の通知,ロック変数,FetchedResultsControllerの初期化を行う.
 写真データが0件の場合は、Download処理を起動.
 */
- (void)viewDidLoad {
  
  NSLog(@"load did load");
  NSLog(@"photo view  viewDidLoad");
  [super viewDidLoad];
  //
  thumbnailLock = [[NSLock alloc] init];
  onAddingThumbnailsLock = [[NSLock alloc] init];

  //
  needToLoadIfWifi = YES;
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
  // 
  self.navigationItem.backBarButtonItem.title = @"album";
  //
  
  lockSave = [[NSLock alloc] init];
  lockForShowingAlbum = [[NSLock alloc] init];
  if(self.album == nil) {
    return;
  }

  // Title設定
  self.navigationItem.title = self.album.title;
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
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

  if(self.album == nil) {
    [self setNoPhotoMessage:[NSNumber numberWithInt:kChooseAlbumMessage]];
    return;
  }
  // コンテンツ view の高さ
  CGRect frame = self.navigationController.view.frame;
  CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
  frame.size.height -= (self.navigationController.toolbar.frame.size.height +
                        self.navigationController.navigationBar.frame.size.height +
                        statusBarFrame.size.height);
  
  self.view.frame = frame;
  
  [onAddingThumbnailsLock lock];
  BOOL skip = onAddingThumbnails;
  [onAddingThumbnailsLock unlock];
  if(skip == YES) {
    return;
  }

  
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kLoadingPhotosMessage]];
  [self loadPhotos:self.album];
}

- (void) afterViewDidAppear:(id)arg {
  //
  [onAddingThumbnailsLock lock];
  [self performSelectorOnMainThread:@selector(discardTumbnails)
                         withObject:nil
                      waitUntilDone:YES];
  [onAddingThumbnailsLock unlock];
  //
  [self performSelectorOnMainThread:@selector(loadThumbnails)
                         withObject:nil
                      waitUntilDone:YES];
}

/*!
 sub view がLayoutされたときの通知.
 機器回転時のレイアウト調整.
 */
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

- (void)viewWillDisappear:(BOOL)animated {
  //
  [super viewWillDisappear:animated];
  if(downloader) {
    [downloader requireStopping];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  // Google問い合わせ中の場合,停止を要求、完了するまで待つ
  if(self.picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
  [self.picasaFetchController requireStopping];
// [self stopToAddThumbnails];
  needToLoadIfWifi = NO;
  needToLoad = NO;
  NSLog(@"photoListViewController didDisappear.retain count = %d", [self retainCount]);
}

#pragma mark -

#pragma mark Device Rotation

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

#pragma mark -

#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"didReceiveMemoryWarning");
  
  // Release any cached data, images, etc that aren't in use.
  [toolbarButtons release];
  toolbarButtons = nil;
  [infoButton release];
  infoButton = nil;
  [refreshButton release];
  refreshButton = nil;
  [photoButton release];
  photoButton = nil;
  [progressView  release];
  progressView = nil;
  [self discardTumbnails];
}

- (void)dealloc {
  NSLog(@"PhotoListViewController dealloc");
  if(progressView) {
  }
  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(self.picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [picasaFetchController release];
    picasaFetchController = nil;
  }
  
  [self discardTumbnails];
  if(progressView)
    [progressView release];
  if(backButton)
    [backButton release];
  if(infoButton)
    [infoButton release];
  if(refreshButton)
    [refreshButton release];
  if(photoButton) {
    [photoButton release];
  }
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
  if(lockForShowingAlbum)
    [lockForShowingAlbum release];
  if(thumbnailLock)
    [thumbnailLock release];
  if(onAddingThumbnailsLock)
    [onAddingThumbnailsLock release];
  [super dealloc];
}

#pragma mark -

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
    }
  
    NSString *message = @"";
    switch ([show integerValue] ) {
      case kNoPhotoMessage:
        message = NSLocalizedString(@"PhotoList.None", @"No Photos");
        break;
      case kLoadingPhotosMessage:
        message = NSLocalizedString(@"PhotoList.Loading", @"No Photos");
        break;
      case kChooseAlbumMessage:
        message = NSLocalizedString(@"PhotoList.Choose", @"Choose a album");
        break;
      default:
        break;
    }
    noPhotoLabel.text = message;
  }
  else {
    if(noPhotoLabel != nil && [noPhotoLabel superview] != nil) {
      [noPhotoLabel removeFromSuperview];
    }
  }
}

#pragma mark -

#pragma mark Thumbnails Handling

- (void)loadThumbnails {
  // このMethod は Main以外のThreadで実行される.
  // なのでUIに関する操作は、performSelectorOnMainThreadでMain Thread Queueへ移動させている。
  
  // thumbnailを保持するコレクションの準備

  
  [self.view setNeedsLayout];
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //NSDate *date0 = [[[NSDate alloc] init] autorelease];	  // for logging
  if([[self photoModelController] photoCount] == 0) {
    [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                           withObject:[NSNumber numberWithInteger:kNoPhotoMessage]
                        waitUntilDone:NO];
  }
  else {
    [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                           withObject:[NSNumber numberWithBool:NO]
                        waitUntilDone:NO];
    for(NSUInteger i = 0; i < [[self photoModelController] photoCount]; ++i) {
      UIView *imageView = [self thumbnailAt:i];
      // ImageViewのView階層への追加を行う(main threadで行う必要がある)
      if(imageView) {
        [self performSelectorOnMainThread:@selector(addImageView:)
                               withObject:imageView 
                            waitUntilDone:NO];
      }
    }
  }
  [self removeProgressView];

  // scrollViewのcontent sizeを設定(main threadで行う必要がある)
  [self performSelectorOnMainThread:@selector(setContentSizeWithImageCount)
                         withObject:nil
                      waitUntilDone:YES];
  //
  [onAddingThumbnailsLock lock];
  onAddingThumbnails = NO;
  [onAddingThumbnailsLock unlock];

  [pool drain];
}

- (void) stopToAddThumbnails {
  [onAddingThumbnailsLock lock];
  stoppingToAddingThumbnailsRequired = YES;
  [onAddingThumbnailsLock unlock];
  while (YES) {
    if([onAddingThumbnailsLock tryLock] == YES) {
      if(onAddingThumbnails == NO) {
        [onAddingThumbnailsLock unlock];
        break;
      }
      [onAddingThumbnailsLock unlock];
    }
    [NSThread sleepForTimeInterval:0.01f];
  }
  return;
}


- (void)discardTumbnails {
  
  [ThumbImageView cleanup];
  
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
  Photo *photoObject = [[self photoModelController] photoAt:index];
  UIImage *image = nil;
  if(photoObject && photoObject.thumbnail) {
    NSLog(@"create thumbnail image");
    image  = [UIImage imageWithData:photoObject.thumbnail];
    imageView = [ThumbImageView viewWithImage:image
                                    withIndex:[NSNumber numberWithInt:index]
                                withContainer:self.view ];
    imageView.userInteractionEnabled = YES;
    imageView.delegate = self;
  }
  else {
    NSLog(@"cat't get photo model object");
  }
  
  [pool drain];
  return imageView;
}

#pragma mark -

#pragma mark UI Parts

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
//    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];
    
    if([self canUpdatePhotos]) {
      photoButton = [[UIBarButtonItem alloc]
                      initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                     target:self
                     action:@selector(photoAction:)];
      [toolbarButtons addObject:photoButton];
      spaceRight = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                    target:self
                    action:nil];
//        spaceRight.width = 30.0f;
      [toolbarButtons addObject:spaceRight];
      [spaceRight release];
    }
    
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

- (void) enableToolbar:(BOOL)enable {
  refreshButton.enabled = enable;
  infoButton.enabled = enable;
}

#pragma mark -

#pragma mark AlbumTableViewControllerDelegate

- (void) albumTableViewControll:(AlbumTableViewController *)controller
                    selectAlbum:(Album *)selectedAlbum {
  [self onAlbumSelected:selectedAlbum];
}


#pragma mark -

#pragma mark PicasaFetchControllerDelegate

-(void) insertedPhotoWithTicket:(GDataServiceTicket *)ticket
          finishedWithPhotoFeed:(GDataFeedPhoto *)feed
                          error:(NSError *)error {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

  if(error) {
    
  }
  else {
    NSLog(@"upload");
    [self performSelector:@selector(refreshPhotos:)
               withObject:NO
               afterDelay:0.0f];
//    [self refreshAction:self];
  }
  
}


// Googleへの問い合わせの応答の通知
// ローカルDBへの登録を行う.
- (void)albumAndPhotosWithTicket:(GDataServiceTicket *)ticket
           finishedWithAlbumFeed:(GDataFeedPhotoAlbum *)feed
                           error:(NSError *)error {
  // view が非表示になった場合
  if([self.view isHidden]) {
    return;
  }
  
  //
  if(nextShowedAlbum != nil) {
    // 問い合わせ中に次のアルバムが選択されたので
    // 現在のアルバムの処理を中断して、次に選択されたアルバムを表示
    [self performSelectorOnMainThread:@selector(onAlbumSelected:)
                           withObject:nextShowedAlbum
                        waitUntilDone:NO];
    return;
  }

  [onAddingThumbnailsLock lock];
  onAddingThumbnails = YES;
  stoppingToAddingThumbnailsRequired = NO;
  [onAddingThumbnailsLock unlock];
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
      Photo *photoModel = [[self photoModelController] selectPhoto:photo hasError:&f];
      
      if(!photoModel ) {
        // Photo entry 未登録時 - 登録する
        if([progressView subviews] != nil) {
          // toolbarのButtonを無効に
          [self enableToolbar:NO];
					// progress 状態表示
          [self.view addSubview:progressView];
        }
        Photo *photoModel =  [[self photoModelController] insertPhoto:photo withAlbum:album.albumId];
        if(photoModel) {
          [self downloadThumbnail:photo withPhotoModel:photoModel];
        }
        else {
          hasErrorInInserting = YES;
        }
      }
      else if(!photoModel.thumbnail) {
        // Photo thumbnail 未登録時 - 登録するThumnail をロード
        [self downloadThumbnail:photo withPhotoModel:photoModel];
      }
      else {
        NSLog(@"count = %d",[[self photoModelController] photoCount]);
        // Photo thumbnail　登録済み - thumbnail 表示
        // pregress view と 写真なしメッセージを非表示
        [self performSelectorOnMainThread:@selector(removeProgressView)
                               withObject:self
                            waitUntilDone:NO ];
        [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                               withObject:[NSNumber numberWithBool:NO]
                            waitUntilDone:NO];
        // thumbnail の追加
        [self performSelectorOnMainThread:@selector(addTbumbnailForPhoto:)
                               withObject:photoModel
                            waitUntilDone:NO];

      }

    }
  }	
  // Photo一覧のFetched Controllerを生成
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  if (![[[self photoModelController] fetchedPhotosController] performFetch:&error]) {
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
  if([[self photoModelController] photoCount] == 0) {
    progressView.progress = 1.0f;
  }
  else {
    progressView.progress = 1.0f / [[self photoModelController] photoCount];
    [progressView setNeedsLayout];
  }
  [downloader start];
  [downloader finishQueuing];
  [pool drain];
//  [picasaFetchController release];
//  picasaFetchController = nil;
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
//  [picasaFetchController release];
//  picasaFetchController = nil;
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
//  [picasaFetchController release];
//  picasaFetchController = nil;
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
//  [picasaFetchController release];
//  picasaFetchController = nil;
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
  [onAddingThumbnailsLock lock];
  BOOL skip = onAddingThumbnails;
  [onAddingThumbnailsLock unlock];
  if(skip == YES) {
    return;
  }
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // 写真表示Viewへ
  NSInteger index = [imageView.index integerValue];
  if(index >= 0 && index < [[self photoModelController] photoCount]) {
    PageControlViewController *pageController =
    [[[PageControlViewController alloc] init] autorelease];
    
    pageController.source = self;
    pageController.curPageNumber = index;
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

- (BOOL) canUpdatePhotos {
  User *user = (User *)self.album.user;
  if(user) {
    SettingsManager *settings = [[SettingsManager alloc] init];
    BOOL ret = [settings isEqualUserId:user.userId] ? YES : NO;
    [settings release];
    return ret;
  }
  return NO;
}

- (void) addTbumbnailForPhoto:(Photo *)photo {
  NSInteger i = [[self photoModelController] indexForPhoto:photo];
  if(i != NSNotFound) {
    UIView *imageView = [self thumbnailAt:i];
    // ImageViewのView階層への追加を行う(main threadで行う必要がある)
    if(imageView) {
      [self addImageView:imageView];
    }
    // scrollViewのcontent sizeを設定(main threadで行う必要がある)
    [self setContentSizeWithImageCount];
  }
}

- (void) onAlbumSelected:(Album *)selectedAlbum {
  if(self.picasaFetchController && self.picasaFetchController.completed == NO) {
    // Google 問い合わせ中に次のアルバムが選択された
    // 問い合わせが返ってくるまで待つため、次の選択アルバムを記録しておいて、一回処理キャンセルしておく
    // 問い合わせが返ってきたときｎ、再度、これを起動する。
    nextShowedAlbum = selectedAlbum;
    return;
  }
  nextShowedAlbum = nil;
  
  
  if(downloader) {
    [downloader requireStopping];
  }
//  [self stopToAddThumbnails];
  if(downloader) {
    [downloader waitCompleted];
  }


  // '写真を読み込んでいます'表示
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kLoadingPhotosMessage]];
  
  needToLoadIfWifi = YES;
  [self discardTumbnails];
  if(downloader != nil && ![downloader isCompleted] && [downloader isStarted]) {
    [[self photoModelController] clearLastAdd];
    [downloader requireStopping];
  }
  
  self.album = selectedAlbum;
  [[self photoModelController] setAlbum:[self album]];
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
    showingAlbum = nil;
    return;
  }
  
  if(needToLoadIfWifi == NO) {	// 写真画面から戻ってきた場合
    // viewのサイズ, 前画面(写真)がtoolbar部分を含んでいたので、そのtoolbar分マイナス
    CGRect frame = self.view.frame;
    frame.size.height -= self.navigationController.toolbar.frame.size.height;
    self.view.frame = frame;
  }
  
  self.view.userInteractionEnabled = YES;
  
}



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


- (void) refreshPhotos:(BOOL)refreshAll {

  hasErrorInDownloading = NO;
  hasErrorInInsertingThumbnail = NO;
  [[self photoModelController] setAlbum:[self album]];
  //
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //  NSArray *objects = [fetchedPhotosController fetchedObjects];
  // toolbarのButtonを無効に
  [self enableToolbar:NO];
  // 削除
  if(refreshAll) {
    [[self photoModelController] removePhotos];
  }
  // 再ロード
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  SettingsManager *settings = [[SettingsManager alloc] init];
  self.picasaFetchController = [[PicasaFetchController alloc] init];
  self.picasaFetchController.delegate = self;
  self.picasaFetchController.userId = settings.userId;
  self.picasaFetchController.password = settings.password;
  [self.view addSubview:[self progressView]];
  [self.picasaFetchController queryAlbumAndPhotos:self.album.albumId
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
  if(needToLoad == YES)
    return YES;
  if(needToLoadIfWifi == NO)
    return NO;
  if([[self photoModelController] album].albumId != curAlbum.albumId) {
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
		return YES;
  }
    
  if ( ( curAlbum.lastAddPhotoAt == nil ||
        [self minutesBetween:curAlbum.lastAddPhotoAt and:[NSDate date] ] > kIntervalForReload)
        &&
      [NetworkReachability reachableByWifi]) {
    return YES;
  }
  BOOL ret = NO;
  // thumbnail の未ロードのものがないかのチェック
  for(int i = 0; i < [modelController photoCount]; ++i) {
    Photo *photoModel = [modelController photoAt:i];
    if(photoModel == nil || photoModel.thumbnail == nil) {
      ret = YES;
      break;
    }
  }
  
  return ret;
}

  
- (BOOL) loadPhotos:(Album *)curAlbum {
  
  downloader = [[QueuedURLDownloader alloc]
                initWithMaxAtSameTime:kDownloadMaxAtSameTime];
  downloader.delegate = self;
  [self discardTumbnails];
  [[self photoModelController] setAlbum:curAlbum];
  
  NSLog(@"fetchedPhotosController");
  NSError *error = nil;

  if (![[[self photoModelController] fetchedPhotosController] performFetch:&error]) {
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
    [self refreshPhotos:YES];
    ret = YES;
  }
  else {
    [self afterViewDidAppear:self];
    ret = NO;

  }
  [pool drain];
  return ret;
}

- (PhotoModelController *) photoModelController {
  if(modelController == nil) {
    modelController = [[PhotoModelController alloc]
                       initWithContext:self.managedObjectContext];
  }
  if(modelController.managedObjectContext == nil) {
    modelController.managedObjectContext = self.managedObjectContext;
  }
  return modelController;
}

#pragma mark -

#pragma mark UI After Download  Handling

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
                                                        @"Error In Downloading")
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
                                                        @"Error In Saving")
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  //
  [self removeProgressView];
  [self setNoPhotoMessage:NO];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
  //
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   //

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
  progressView.progress = progressView.progress + (1.0 / [[self photoModelController] photoCount] );
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  [onAddingThumbnailsLock lock];
  if(stoppingToAddingThumbnailsRequired) {
    [onAddingThumbnailsLock unlock];
    onAddingThumbnails = NO;
//    [self discardTumbnails];
    return;
  }
  [onAddingThumbnailsLock unlock];
  
  Photo *photo = (Photo *)[info objectForKey:@"photo"];
  if(photo) {
    if( [[self photoModelController] updateThumbnail:data forPhoto:photo] == nil) {
      hasErrorInInsertingThumbnail = YES;
    }
  }
  // pregress view と 写真なしメッセージを非表示
  [self performSelectorOnMainThread:@selector(removeProgressView)
                         withObject:self
                      waitUntilDone:NO ];
  [self performSelectorOnMainThread:@selector(setNoPhotoMessage:)
                         withObject:[NSNumber numberWithBool:NO]
                      waitUntilDone:NO];
  // thumbnail の追加
  [self performSelectorOnMainThread:@selector(addTbumbnailForPhoto:)
                         withObject:photo
                      waitUntilDone:NO];
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
  [urlDownloader release];
  urlDownloader = nil;
  downloader = nil;
  // albumのphotoに対する最後の保存処理実行日時を記録
  [[self photoModelController] setLastAdd];

  //
  [self performSelectorOnMainThread:@selector(downloadCompleted)
                         withObject:nil
                      waitUntilDone:NO];
  [onAddingThumbnailsLock lock];
  onAddingThumbnails = NO;
  [onAddingThumbnailsLock unlock];


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
                      waitUntilDone:NO];

}

#pragma mark -

#pragma mark Action

- (void) photoAction:(id)sender {
  UIActionSheet *sheet;
  if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    sheet = [[UIActionSheet alloc]
            initWithTitle:@""
            delegate:self
            cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
            destructiveButtonTitle:nil
            otherButtonTitles:NSLocalizedString(@"Camera",@"by email"),
            NSLocalizedString(@"PhotoLibrary",@"photo library"),
            nil];
  }
  else {
    sheet = [[UIActionSheet alloc]
             initWithTitle:@""
             delegate:self
             cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
             destructiveButtonTitle:nil
             otherButtonTitles:
             NSLocalizedString(@"PhotoLibrary",@"photo library"),
             nil];
  }
  
  [sheet showFromToolbar:self.navigationController.toolbar];
}

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
  [self setNoPhotoMessage:[NSNumber numberWithInteger:kLoadingPhotosMessage]];
  [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                             @"download")];
  [self discardTumbnails];
  [self.view addSubview:progressView];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [self refreshPhotos:YES];
  
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
    [self performSelectorOnMainThread:@selector(refreshPhotos:)
                           withObject:YES
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

#pragma mark UIActionSheetDelegate

/*!
 
 */
- (void)actionSheet:(UIActionSheet *)actionSheet
clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  NSInteger sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  NSLog(@"action sheet - selected index = %d", buttonIndex);
  //  UIViewController *contoller ;
  switch (buttonIndex) {
    case 0:	  // カメラ
      if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
      }
      break;
    case 1:	  // ライブラリ
      if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
      }
      break;
    default:
      return;
  }
  UIPopoverController *popover;
  UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
  [imagePickerController setSourceType:sourceType];
  [imagePickerController setDelegate:self];
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad &&
      sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
    
    popover = [[UIPopoverController alloc]initWithContentViewController:imagePickerController];
		[popover presentPopoverFromBarButtonItem:photoButton
                    permittedArrowDirections:UIPopoverArrowDirectionAny
                                    animated:YES];

  }
  else {
    [self presentViewController:imagePickerController animated:YES completion:nil];
  }
  

}

#pragma mark UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {

  UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
  NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
  SettingsManager *settings = [[SettingsManager alloc] init];
//  picasaFetchController = [[PicasaFetchController alloc] init];
//  picasaFetchController.userId = settings.userId;
//  picasaFetchController.password = settings.password;

  if(!self.picasaFetchController) {
    self.picasaFetchController = [[PicasaFetchController alloc] init];
    self.picasaFetchController.delegate = self;
    self.picasaFetchController.userId = settings.userId;
    self.picasaFetchController.password = settings.password;

  }
  [settings release];
  User *user = (User *)self.album.user;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  [self.picasaFetchController insertPhoto:imageData
                                 withAlbum:self.album.albumId
                                  withUser:user.userId];
  [self dismissViewControllerAnimated:YES
                           completion:^{
                           }];
//  [NSData alloc] ini
  
}


#pragma mark PageViewSource

- (NSUInteger) pageCount {
  return [[self photoModelController] photoCount];
  
}

- (UIViewController<PageViewDelegate> *) pageAt:(NSUInteger)n {
  PhotoViewController *viewController = [[PhotoViewController alloc] 
                                         initWithNibName:@"PhotoViewController" 
                                         bundle:nil];
  viewController.fetchedPhotosController = [[self photoModelController] fetchedPhotosController];
  viewController.managedObjectContext = self.managedObjectContext;
  viewController.indexForPhoto = n;
  return viewController;
}

#pragma mark -


@end
