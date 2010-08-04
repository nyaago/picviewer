//
//  PhotoListViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotoListViewController.h"
#import "PhotoViewController.h"
#import "Photo.h"
#import "Album.h"
#import "PageControlViewController.h"
#import "AlbumInfoViewController.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

#define kDownloadMaxAtSameTime 5

@interface PhotoImageView : UIImageView
{
  PhotoListViewController *listViewController;
}

- (id) initWithImage:(UIImage *)image 
withListViewController:(PhotoListViewController *)controller;

@end

@implementation PhotoImageView

- (id) initWithImage:(UIImage *)image 
withListViewController:(PhotoListViewController *)controller {
  self = [super initWithImage:image];
  if(self) {
    listViewController = controller;
    //	[listViewController retain];
  }
  return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if(listViewController)
    [listViewController touchesEnded:touches withEvent:event];
}


- (void) dealloc {
  //  if(listViewController)
  //	[listViewController release];
  [super dealloc];
}

@end



@interface  PhotoListViewController (Private)


/*!
 Thumbnailを表示する座標
 */
- (CGPoint) pointForThumb:(NSUInteger)n;

/*!
 Thumbnailを表示するImageViewのFrameのRectを返す
 */
- (CGRect) frameForThums:(NSUInteger)n;

/*!
 Viewが何番目のIndexの写真であるかを返す
 */
- (NSUInteger) indexForPhoto:(UIView *)targetView;

/*!
 @method thumbWidth
 @discussion thumbnailの幅
 */
- (NSUInteger) thumbWidth;

/*!
 @method thumbHeigth
 @discussion thumbnailの高さ
 */
- (NSUInteger) thumbHeight;


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
 @method setContentSizeWithImageCount: 
 @discussion scrollViewのコンテンツサイズを設定.
 この処理は、Thread切り替えして起動する(
 performSelectorOnMainThread:withObject:waitUntilDone: で)
 必要があるため、メソッドとして定義。
 @param n scrollViewに表示されるImageView(thumbnail)の数(NSNumber *)
 */
- (void)setContentSizeWithImageCount:(id)n;

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
- (BOOL)mustLoad;

/*!
 @method mustRefresh
 @discussion データの全ロードを行うがどうかの判定
 */
- (BOOL)mustRefresh;

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
  NSLog(@"load viee");
  // thumbnailを保持するコレクションの準備
  if(thumbnails == nil) {
    thumbnails = [[NSMutableDictionary alloc] init];
  }
  // progressView
  CGRect frame = CGRectMake(0.0f, self.view.frame.size.height - 200.0f , 
                            self.view.frame.size.width, 200.0f);
  progressView = [[LabeledProgressView alloc] initWithFrame:frame];
  // toolbar
  self.toolbarItems = [self toolbarButtons];
//  self.navigationController.toolbar.translucent = YES;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbarHidden = NO; 
//  [self setToolbarItems: [self toolbarButtons] animated:YES];
  // scrollViewのサイズ
//  frame = self.scrollView.frame;
//  frame.size.height -= self.navigationController.toolbar.frame.size.height;
//  self.scrollView.frame = frame;
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
  lockSave = [[NSLock alloc] init];
  modelController = [[PhotoModelController alloc] 
                     initWithContext:self.managedObjectContext 
                     withAlbum:self.album];
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
    return;
  }
  // Photoが0件であれば、Googleへの問い合わせを起動.
  // 問い合わせ結果は、albumAndPhotoWithTicket:finishedWithUserFeed:errorで受け
  // CoreDataへの登録を行う
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if([self mustLoad]) {

    // クリア + 全ロードか?
    onRefresh = [self mustRefresh];
      
    // toolbarのButtonを無効に
    [self enableToolbar:NO];
    // progress View
    progressView.progress = 0.0f;
    [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                               @"download")];
    if(onRefresh) {
      [self.view addSubview:progressView];
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // 
    SettingsManager *settings = [[SettingsManager alloc] init];
    picasaFetchController = [[PicasaFetchController alloc] init];
    picasaFetchController.delegate = self;
    picasaFetchController.userId = settings.userId;
    picasaFetchController.password = settings.password;
    [picasaFetchController queryAlbumAndPhotos:self.album.albumId 
                                          user:[self.album.user valueForKey:@"userId"] 
                                 withPhotoSize:[NSNumber numberWithInt:settings.imageSize]];
    
    downloader = [[QueuedURLDownloader alloc] 
                  initWithMaxAtSameTime:kDownloadMaxAtSameTime];
    downloader.delegate = self;
    [settings release];
  }
  else {
  }
  [pool drain];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.wantsFullScreenLayout = NO;

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
  NSLog(@"thumbnail count = %d", [thumbnails count]);
  /*
  self.navigationController.toolbarHidden = NO;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  **/
  // tool bar
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  
  if(isFromAlbumTableView == NO) {	// 写真画面から戻ってきた場合
    // scrollViewのサイズ
    CGRect frame = self.view.frame;
    frame.size.height -= self.navigationController.toolbar.frame.size.height;
    self.scrollView.frame = frame;
  }
  else {
    // Thumbnailを表示するImageViewがview階層に追加されるたびにそれらが画面表示されるよう
    // (最後に一括して表示されるのではなく)、表示処理のloopを別Threadで起動、
    // ただし、実際のview階層への追加はこのmain Threadに戻って行われることになる(
    // 表示関連の操作はmain Threadでされる必要があるので)
    [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:) 
                             toTarget:self 
                           withObject:nil];
    isFromAlbumTableView = YES;
  }
}

- (void) afterViewDidAppear:(id)arg {
  
  
  if([thumbnails count] != 0) {
    [self discardTumbnails];
  }
  [self loadThumbnails];
}


- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"didReceiveMemoryWarning");
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidDisappear:(BOOL)animated {
  // Google問い合わせ中の場合,停止を要求、完了するまで待つ
  if(picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
  
  // Download実行中の場合,停止を要求、完了するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
  [self stopToAddThumbnails];
}

- (void)viewDidUnload {
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  NSLog(@"PhotoListViewController viewDidUnload ");
  NSLog(@"lockSave retain count = %d", [lockSave retainCount]);
  NSLog(@"backBUtton retain count = %d", [backButton retainCount]);
  NSLog(@"album retain count = %d", [album retainCount]);
  NSLog(@"managedObjectContext retain count = %d", [managedObjectContext retainCount]);
  NSLog(@"thumbnails count = %d", [thumbnails count]);
  NSLog(@"thumbnails retain count = %d", [thumbnails retainCount]);
  
  [super viewDidUnload];
  [lockSave release];
  lockSave = nil;
  [downloader release];
  downloader = nil;
  [self discardTumbnails];
  NSLog(@"discard thumbnails count = %d", [thumbnails count]);
  
}

- (void)dealloc {
  NSLog(@"PhotoListViewController dealloc");
  if(progressView) {
    NSLog(@"progressView retain count = %d", [progressView retainCount]);
  }
  NSLog(@"backBUtton retain count = %d", [backButton retainCount]);
  NSLog(@"album retain count = %d", [album retainCount]);
  NSLog(@"managedObjectContext retain count = %d", [managedObjectContext retainCount]);
  NSLog(@"thumbnails count = %d", [thumbnails count]);
  NSLog(@"thumbnails retain count = %d", [thumbnails retainCount]);
  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(picasaFetchController) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [picasaFetchController release];
    picasaFetchController = nil;
  }
  
  // ダウンロード中であれば、ダウンロード停止要求をして、停止するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [downloader release];
    downloader = nil;
  }
  [self discardTumbnails];
  [thumbnails release];
  if(progressView)
    [progressView release];
  if(backButton)
    [backButton release];
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
  [super dealloc];
}

#pragma mark Method For performing on MainThread

- (void)addImageView:(id)imgView {
  UIView *v = (UIView *)imgView;
  [self.scrollView addSubview:v];
}

- (void)setContentSizeWithImageCount:(id)n {
  
  NSNumber *number = (NSNumber *)n;
  CGPoint point = [self pointForThumb:[number intValue]];
  self.scrollView.contentSize =  CGSizeMake(self.scrollView.frame.size.width, 
                                            point.y + 80.0f);
}

#pragma mark -

- (void)loadThumbnails {
  [onAddingThumbnailsLock lock];
  onAddingThumbnails = YES;
  stoppingToAddingThumbnailsRequred = NO;
  [onAddingThumbnailsLock unlock];
  
  [self.view setNeedsLayout];
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  //NSDate *date0 = [[[NSDate alloc] init] autorelease];	  // for logging
  for(NSUInteger i = 0; i < [modelController photoCount]; ++i) {
    /*
     NSDate *date1 = [[[NSDate alloc] init] autorelease];  // for logging
     */
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
    
    /*
     NSDate *date2 = [[[NSDate alloc] init] autorelease];
     NSLog(@"interval creating imageView and adding to view layers = %f", 
     [date2 timeIntervalSinceDate:date1]);
     */
  }
  /*
  NSDate *date3 = [[[NSDate alloc] init] autorelease];	// for logging
  NSLog(@"interval creating all views for a thumbnail = %f", 
        [date3 timeIntervalSinceDate:date0]);
  */
  // scrollViewのcontent sizeを設定(main threadで行う必要がある)
  [self performSelectorOnMainThread:@selector(setContentSizeWithImageCount:) 
                         withObject:[NSNumber numberWithInt:[modelController photoCount]] 
                      waitUntilDone:NO];
  [onAddingThumbnailsLock lock];
  onAddingThumbnails = NO;
  stoppingToAddingThumbnailsRequred = NO;
  [onAddingThumbnailsLock unlock];
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
  NSInteger n = [modelController photoCount];
  for(NSUInteger i = 0; i < n; ++i) {
    [self discardTumbnailAt:i];
  }
  //  [thumbnails removeAllObjects];
}

- (void)discardTumbnailAt:(NSUInteger)index {
  NSLog(@"discard imageView - %@", [thumbnails 
                                    objectForKey:[NSNumber numberWithInt:index]]);
  
  UIImageView *imageView 
  = (UIImageView *)[thumbnails objectForKey:[NSNumber numberWithInt:index]];
  if(imageView != nil) {
    NSLog(@"do discad view ");
    if([imageView superview] ) {
      [imageView removeFromSuperview];
    }
    [imageView release];
  }
  [thumbnails removeObjectForKey:[NSNumber numberWithInt:index]];
}


- (UIView *)thumbnailAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  UIView *imageView = nil;
  imageView = (UIImageView *)[thumbnails objectForKey:[NSNumber numberWithInt:index]];
  NSUInteger indexes[2];
  indexes[0] = 0;
  
  if(!imageView) {
    // 画像データを取得してUIImageViewを生成
    indexes[1] = index;
    Photo *photoObject = [modelController photoAt:index];
    UIImage *image = nil;
    if(photoObject.thumbnail) {
      image  = [UIImage imageWithData:photoObject.thumbnail];
      imageView = [[PhotoImageView alloc] initWithImage:image withListViewController:self];
      imageView.userInteractionEnabled = YES;
      [thumbnails setObject:imageView forKey:[NSNumber numberWithInt:index]];
    }
    else {
      imageView = nil;
    }
    imageView.frame = [self frameForThums:index];
    // UIImageViewをDictinaryに登録しておく
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
                                                        @"Error in ng")
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
  [progressView removeFromSuperview];
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
  [progressView removeFromSuperview];
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
  [progressView removeFromSuperview];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
}



#pragma mark -


#pragma mark Touch

/*
 touch終了
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if(onScroll == YES) {
    onScroll = NO;
    return;
  }
  UITouch *touch = [touches anyObject];
  UIView *touchView = touch.view;
  //  if([touchView is: UIImageView.class]) {
  // 写真表示Viewへ
  NSInteger index = [self indexForPhoto:touchView];
  if(index >= 0 && index < [modelController photoCount]) {
    PageControlViewController *pageController = 
    [[PageControlViewController alloc] init];
    self.navigationItem.backBarButtonItem = [PhotoViewController backButton];
    NSLog(@"init PageControllerView retain count = %d",[pageController retainCount]);
    pageController.source = self;
    pageController.curPageNumber = index;
    NSLog(@"begore push PageControllerView retain count = %d",[pageController retainCount]);
    [self.navigationController pushViewController:pageController animated:YES];
    [pageController release];
    NSLog(@"push PageControllerView retain count = %d",[pageController retainCount]);
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  onScroll = NO;
  [super touchesBegan:touches withEvent:event];
  //  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  onScroll = YES;
  [super touchesMoved:touches withEvent:event];
  //  [[self nextResponder] touchesMoved:touches withEvent:event];
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


- (CGPoint) pointForThumb:(NSUInteger)n {
//  NSLog(@"width = %f, height = %f", self.scrollView.bounds.size.width, 
//        self.scrollView.bounds.size.height);
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  NSUInteger cols = self.scrollView.bounds.size.width / w;
  NSUInteger row = n / cols;	// base - 0
  NSUInteger col = n % cols;	// base - 0
  return CGPointMake(col * h + padding, row * w + padding);
}

- (CGRect) frameForThums:(NSUInteger)n {
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  CGPoint point = [self pointForThumb:n];
  return CGRectMake(point.x, point.y, w - padding * 2, h - padding *2);
}

- (NSUInteger) indexForPhoto:(UIView *)targetView {
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  CGRect frame = [targetView frame];
  CGPoint point = frame.origin;
  NSInteger x = (NSInteger)point.x;
  NSInteger y = (NSInteger)point.y;
  NSInteger col = x / (NSInteger)h;
  NSInteger row = y / (NSInteger)w;
  NSInteger colByRow = 
  				(NSInteger)self.scrollView.bounds.size.width / (NSInteger)w;
  return row * colByRow + col;
}

- (NSUInteger) thumbWidth {
  NSInteger w = self.view.frame.size.width;
  if(w > 640) {
    return w / 6;
  }
  else {
    return w / 4;
  }
}

- (NSUInteger) thumbHeight {
  NSInteger w = self.view.frame.size.width;
  if(w > 640) {
    return w / 6;
  }
  else {
    return w / 4;
  }
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
  [picasaFetchController queryAlbumAndPhotos:self.album.albumId 
                                        user:[self.album.user valueForKey:@"userId"]
                               withPhotoSize:[NSNumber numberWithInt:settings.imageSize]];
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

- (BOOL)mustLoad {

  if(isFromAlbumTableView == NO)
    return NO;
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
    
  if ( [self minutesBetween:album.lastAddPhotoAt and:[NSDate date] ] > 15 && 
      [NetworkReachability reachableByWifi]) {
    return YES;
  }
  return NO;
}

- (BOOL)mustRefresh {
  if([modelController photoCount] == 0) {
    return YES;
  }
  return NO;
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
- (void)didAllCompleted {
  // 表示をリフレッシュ
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
  
  [progressView removeFromSuperview];
  [downloader release];
  downloader = nil;
  // albumのphotoに対する最後の保存処理実行日時を記録
  [modelController setLastAdd];
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
  //
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:) 
                           toTarget:self 
                         withObject:nil];
}

/*!
 ダウンロードキャンセル時の通知
 */
- (void)dowloadCanceled {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // toolbarのボタンを有効に
  [self enableToolbar:YES];
}



#pragma mark Action

- (void) refreshAction:(id)sender {
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
    return;
  }
  /*
  progressView.frame = CGRectMake(50.0f, 20.0f, 
                                  self.view.bounds.size.width - 100.0f, 
                                  25.0f);
   */
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

- (void) infoAction:(id)sender {
  
  AlbumInfoViewController *viewController = [[AlbumInfoViewController alloc]
                                             initWithNibName:@"AlbumInfoViewController" 
                                             bundle:nil];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  
  viewController.album = self.album;
  [self.view.window bringSubviewToFront:self.view];
  [[self parentViewController] presentModalViewController:navigationController 
                                                 animated:YES];
	[viewController release];
  [navigationController release];
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
