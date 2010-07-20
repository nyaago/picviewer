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
 @method insertPhoto:withAlbum
 @discussion Photo情報をローカルDBに登録する.
 */
- (Photo *)insertPhoto:(GDataEntryPhoto *)photo   withAlbum:(Album *)user;
/*!
 @method updateThumbnail:forPhoto
 @discussion PhotoのThumbnailをローカルDBに更新登録する.
 @return 正常であれば、挿入したModelObject, エラーであればnil
 */
- (Photo *)updateThumbnail:(NSData *)thumbnailData forPhoto:(Photo *)photo;
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
 @method removePhotos
 @discussion 現在のAlbumのPhotoデータを全て削除
 */
- (void)removePhotos;

/*!
 @method enableToolbar:
 @discussion toolbarのButtonの有効無効の切り替え
 */
- (void) enableToolbar:(BOOL)enable;


@end




@implementation PhotoListViewController

@synthesize fetchedPhotosController, managedObjectContext;
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
  self.scrollView.scrollEnabled = YES;
  self.scrollView.userInteractionEnabled = YES;
  self.scrollView.frame = self.view.bounds;
  self.scrollView.backgroundColor = [UIColor blackColor];
  NSLog(@"load viee");
  if(thumbnails == nil) {
    thumbnails = [[NSMutableDictionary alloc] init];
  }
  CGRect frame = CGRectMake(0.0f, self.view.frame.size.height - 200.0f , 
                            self.view.frame.size.width, 200.0f);
  progressView = [[LabeledProgressView alloc] initWithFrame:frame];
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
  NSLog(@"fetchedPhotosController");
  // fetchedResultsControllerのメモリを一回クリア(メモリ圧迫するので)
  /*
   if(fetchedPhotosController) {
   NSLog(@"photo list view did load - fetchedPhotosController retainCount = %d",
   [fetchedPhotosController retainCount]);
   [fetchedPhotosController release];
   fetchedPhotosController = nil;
   
   //	if([fetchedPhotosController retainCount] == 0)
   }
   */
  NSError *error = nil;
  if (![[self fetchedPhotosController] performFetch:&error]) {
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
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  if([sectionInfo numberOfObjects] == 0) {
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
    // toolbarのButtonを無効に
    [self enableToolbar:NO];
		// progress View
    progressView.progress = 0.0f;
    [progressView setMessage:NSLocalizedString(@"PhotoList.DownloadList",
                                               @"download")];
    [self.view addSubview:progressView];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // 
    SettingsManager *settings = [[SettingsManager alloc] init];
    picasaFetchController = [[PicasaFetchController alloc] init];
    picasaFetchController.delegate = self;
    picasaFetchController.userId = settings.userId;
    picasaFetchController.password = settings.password;
    [picasaFetchController queryAlbumAndPhotos:self.album.albumId 
                                          user:[self.album.user valueForKey:@"userId"] ];
    
    downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:2];
    downloader.delegate = self;
    [settings release];
  }
  else {
  }
  [self setToolbarItems: [self toolbarButtons] animated:YES];
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
	self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.translucent = YES;
  self.navigationController.toolbarHidden = NO; 
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
  self.wantsFullScreenLayout = YES;
  self.navigationController.toolbarHidden = NO;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = YES;
  
  
  
  // Thumbnailを表示するImageViewがview階層に追加されるたびにそれらが画面表示されるよう
  // (最後に一括して表示されるのではなく)、表示処理のloopを別Threadで起動、
  // ただし、実際のview階層への追加はこのmain Threadに戻って行われることになる(
  // 表示関連の操作はmain Threadでされる必要があるので)
  [NSThread detachNewThreadSelector:@selector(afterViewDidAppear:) 
                           toTarget:self 
                         withObject:nil];
}

- (void) afterViewDidAppear:(id)arg {
  
  
  if([thumbnails count] == 0)
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
  if(fetchedPhotosController)
    NSLog(@"fetchedPhotosController retain count = %d", 
          [fetchedPhotosController retainCount]);
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
  if(fetchedPhotosController)
    NSLog(@"fetchedPhotosController retain count = %d", 
          [fetchedPhotosController retainCount]);
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
  if(managedObjectContext)
    [managedObjectContext release];
  if(fetchedPhotosController) {
    [fetchedPhotosController release];
    fetchedPhotosController = nil;
  }
  if(lockSave)
    [lockSave release];
  [self discardTumbnails];
  [thumbnails release];
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
  NSDate *date0 = [[[NSDate alloc] init] autorelease];	  // for logging
  for(NSUInteger i = 0; i < [self thumbnailCount]; ++i) {
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
  
  NSDate *date3 = [[[NSDate alloc] init] autorelease];	// for logging
  NSLog(@"interval creating all views for a thumbnail = %f", 
        [date3 timeIntervalSinceDate:date0]);
  
  // scrollViewのcontent sizeを設定(main threadで行う必要がある)
  [self performSelectorOnMainThread:@selector(setContentSizeWithImageCount:) 
                         withObject:[NSNumber numberWithInt:[self photoCount]] 
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
  NSInteger n = [self thumbnailCount];
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

- (Photo *)photoAt:(NSUInteger)index {
  NSUInteger indexes[2];
  if(index >= [self photoCount])
    return nil;
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  
  return photoObject;
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
    Photo *photoObject = [fetchedPhotosController 
                          objectAtIndexPath:[NSIndexPath 
                                             indexPathWithIndexes:indexes length:2]];
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


- (NSUInteger)photoCount {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
}


- (NSUInteger)thumbnailCount {
  return [self photoCount];
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
  [fetchedPhotosController release];
  fetchedPhotosController = nil;
  // 削除
  [self removePhotos];
  
  // ローカルDBへの保存
  NSArray *entries = [feed entries];
  if ([entries count] > 0) {
    NSLog(@"the album has %d photos", [[feed entries] count]);
    for (int i = 0; i < [entries count]; ++i) {
      GDataEntryPhoto *photo = [entries objectAtIndex:i];
      NSLog(@"photo - title = %@, ident=%@, feedlink=%@",
            [[photo title] contentStringValue], [photo GPhotoID], [photo feedLink]);
      //  [self queryPhotoAlbum:[album GPhotoID] user:[album username]];
      Photo *photoModel =  [self insertPhoto:photo withAlbum:album];
      if(photoModel) {
        [self downloadThumbnail:photo withPhotoModel:photoModel];
      }
      else {
        hasErrorInInserting = YES;
      }
    }
  }	
  // Photo一覧のFetched Controllerを生成
  if (![[self fetchedPhotosController] performFetch:&error]) {
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
  if([self thumbnailCount] == 0) {
    progressView.progress = 1.0f;
  }
  else {
    progressView.progress = 1.0f / [self thumbnailCount];
  }
  [downloader start];
  [downloader finishQueuing];
  [pool drain];
  [picasaFetchController release];
  picasaFetchController = nil;
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

#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedPhotosController {
  
  if (fetchedPhotosController != nil) {
    return fetchedPhotosController;
  }
  [NSFetchedResultsController deleteCacheWithName:nil];
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
  [fetchRequest setPredicate:predicate];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" 
                                                                 ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedPhotosController = [[NSFetchedResultsController alloc] 
                                                          initWithFetchRequest:fetchRequest 
                                                          managedObjectContext:managedObjectContext 
                                                          sectionNameKeyPath:nil 
                                                          cacheName:@"Root"];
  aFetchedPhotosController.delegate = self;
  self.fetchedPhotosController = aFetchedPhotosController;
  
  [aFetchedPhotosController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  
  return fetchedPhotosController;
}    

- (void)removePhotos {
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
  [fetchRequest setPredicate:predicate];
  
  NSError *error;
  // データの削除、親(album)からの関連の削除 + (albumに含まれる)全Photoデータの削除
  NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	NSSet *set = [NSSet setWithArray:items];
  [album removePhoto:set];
  for (NSManagedObject *managedObject in items) {
    [managedObjectContext deleteObject:managedObject];
    NSLog(@" object deleted");
  }
  //
  if (![managedObjectContext save:&error]) {
    NSLog(@"Error deleting- error:%@",error);
  }
  [fetchRequest release];
	//[items release];  
  return;
}    


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
  if(index >= 0 && index < [self photoCount]) {
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

- (Photo *)insertPhoto:(GDataEntryPhoto *)photo   withAlbum:(Album *)album {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *photoId = [photo GPhotoID];
  // 新しい永続化オブジェクトを作って
  Photo *photoObject 
  = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                           inManagedObjectContext:managedObjectContext];
  // 値を設定
  [photoObject setValue:photoId forKey:@"photoId"];
  [photoObject setValue:[[photo title] contentStringValue] forKey:@"title"];
  [photoObject setValue:[[photo timestamp] dateValue] forKey:@"timeStamp"];
  if([photo geoLocation]) {
	  [photoObject setValue:[[photo geoLocation] coordinateString] forKey:@"location"];
  }
  if([photo description] ) {
		[photoObject setValue:[photo description] forKey:@"descript"];
  }
  if([photo width] ) {
    [photoObject setValue:[photo width] forKey:@"width"];
  }
  if([photo height] ) {
    [photoObject setValue:[photo height] forKey:@"height"];
  }
  
  // 画像url
  if([[[photo mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[photo mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    [photoObject setValue:[thumbnail URLString] forKey:@"urlForThumbnail"];
  }
  if([[[photo mediaGroup] mediaContents] count] > 0) {
    GDataMediaContent *content = [[[photo mediaGroup] mediaContents]  
                                  objectAtIndex:0];
    NSLog(@"URL for the photo - %@", [content URLString] );
    [photoObject setValue:[content URLString] forKey:@"urlForContent"];
  }
  
  // Save the context.
  NSError *error = nil;
  if ([self.album respondsToSelector:@selector(addPhotoObject:) ] ) {
    [self.album addPhotoObject:(NSManagedObject *)photoObject];
  }	
  [lockSave lock];
  if (![managedObjectContext save:&error]) {
    // 
    [lockSave unlock];
    NSLog(@"Unresolved error %@", error);
    NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"  %@", [error userInfo]);
		}
    
    [pool drain];
    return nil;	
  }
  //  [managedObjectContext processPendingChanges]:
  [lockSave unlock];
  [pool drain];
  return photoObject;
}

- (Photo *)updateThumbnail:(NSData *)thumbnailData forPhoto:(Photo *)photo {
  if(!photo)
    return nil;
  if(!thumbnailData || [thumbnailData length] == 0) 
    return photo;
  photo.thumbnail = thumbnailData;
  NSError *error = nil;
  [lockSave lock];
  if (![managedObjectContext save:&error]) {
    // 
    [lockSave unlock];
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  [lockSave unlock];
  return photo;
  
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


- (CGPoint) pointForThumb:(NSUInteger)n {
//  NSLog(@"width = %f, height = %f", self.scrollView.bounds.size.width, 
//        self.scrollView.bounds.size.height);
  NSUInteger cols = self.scrollView.bounds.size.width / 80.0f;
  NSUInteger row = n / cols;	// base - 0
  NSUInteger col = n % cols;	// base - 0
  return CGPointMake(col * 80.0f + 1.0f, row * 80.0f + 1.0f);
}

- (CGRect) frameForThums:(NSUInteger)n {
  CGPoint point = [self pointForThumb:n];
  return CGRectMake(point.x, point.y, 80.0f - 2.0f, 80.0f - 2.0f);
}

- (NSUInteger) indexForPhoto:(UIView *)targetView {
  CGRect frame = [targetView frame];
  CGPoint point = frame.origin;
  NSInteger x = (NSInteger)point.x;
  NSInteger y = (NSInteger)point.y;
  NSInteger col = x / (NSInteger)80.0f;
  NSInteger row = y / (NSInteger)80.0f;
  NSInteger colByRow = 
  				(NSInteger)self.scrollView.bounds.size.width / (NSInteger)80.0f;
  return row * colByRow + col;
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
                                        user:[self.album.user valueForKey:@"userId"]];
  downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:2];
  downloader.delegate = self;
  [settings release];
  [pool drain];
  
}

- (void) enableToolbar:(BOOL)enable {
  refreshButton.enabled = enable;
  infoButton.enabled = enable;
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
  progressView.progress = progressView.progress + (1.0 / [self thumbnailCount] );
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  Photo *photo = (Photo *)[info objectForKey:@"photo"];
  if(photo) {
    if( [self updateThumbnail:data forPhoto:photo] == nil) {
      hasErrorInInsertingThumbnail = YES;
    }
  }
  progressView.progress = progressView.progress + 
  (1.0 / [self thumbnailCount] );
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
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
  
}

- (UIViewController<ScrolledPageViewDelegate> *) pageAt:(NSUInteger)n {
  PhotoViewController *viewController = [[PhotoViewController alloc] 
                                         initWithNibName:@"PhotoViewController" 
                                         bundle:nil];
  viewController.fetchedPhotosController = self.fetchedPhotosController;
  viewController.managedObjectContext = self.managedObjectContext;
  viewController.indexForPhoto = n;
  return viewController;
}



@end
