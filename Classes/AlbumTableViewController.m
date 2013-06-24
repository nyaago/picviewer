//
//  AlbumTableViewController.m
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

#import "PicasaViewerAppDelegate.h"
#import "AlbumTableViewController.h"
#import "PhotoListViewController.h"
#import "Album.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

@interface AlbumTableViewController(Private)

// Album の Reload確認を行う間隔（分）
#define kIntervalForReloadWifi 15


/*!
 @method downloadThumbnail:withAlbumModel
 @discussion AlbumのThumbnailをダウンロードする.
 @param album Googleから取得したAlbum情報
 @param model ローカルDB上のAlbumのModelデータ
 */
- (void) downloadThumbnail:(GDataEntryPhotoAlbum *)album withAlbumModel:(Album *)model;

/*!
 @method refreshAction:
 @discussion album一覧のリフレッシュおこなうアクション
 */
- (void) refreshAction:(id)sender;

/*!
 @method refreshAlbum
 @discussion album一覧のリフレッシュ、一覧のalbumについて、新規作成、変更、削除の
 いずれを行い、再表示を行う。
 */
- (void) refreshAlbums;

/*!
 @method refreshTable
 @discussion tableの表示リフレッシュ
 */
- (void) refreshTable;

/*!
 @method enableToolbar:
 @discussion toolbarのButtonの有効無効の切り替え
 */
- (void) enableToolbar:(BOOL)enable;

/*!
 @method insertOrUpdateAlbumsWithUserFeed:withUser:hasError:
 @discussion albumモデルへの挿入または更新
 @param album Googleより取得したalbumデータ
 @param userObject userモデル
 @param f エラー有無
 */
- (void)insertOrUpdateAlbumsWithUserFeed:(GDataFeedPhotoUser *)album
                                withUser:(User *)userObject
                                hasError:(BOOL *)f;


/*!
 @method photoListViewControllerWithAlbum:
 @return Photo一覧のview controller
 @param album albumモデル
 */
- (PhotoListViewController *)photoListViewControllerWithAlbum:(Album *)album;

/*!
 @method mustLoad
 @discussion 
 */
- (BOOL) mustLoad:(User *)curUser;

/*!
 @method daysBetween:and:
 @discussion 日付オブジェクトの時間差を返す.
 */
- (NSInteger)minutesBetween:(NSDate *)d1 and:(NSDate *)d2;

@end


@implementation AlbumTableViewController

@synthesize managedObjectContext;
@synthesize user;

#pragma mark View lifecycle

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically 
 and want to perform customization that is not appropriate for viewDidLoad.
 if (self = [super initWithStyle:style]) {
 }
 return self;
 }
 */


- (void)loadView {
  [super loadView];
  NSLog(@"title = %@", self.navigationItem.backBarButtonItem.title);
  onLoadLock = [[NSLock alloc] init];
}


// View Load時の通知.Navigation BarのButtonの追加と
// Album一覧の取得を行う.ローカルDBにAlbumがなければGoogleへの問い合わせを起動する.
- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = nil;
  if(user == nil) {
    return;
  }
  modelController = [[AlbumModelController alloc] 
                     initWithContext:self.managedObjectContext 
                     withUser:self.user];
  
  NSError *error = nil;
  if (![[modelController fetchedAlbumsController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error",@"Error")
                              message:NSLocalizedString(@"Error.Fetch", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  // Albumが0件であれば、Googleへの問い合わせを起動.
  // 問い合わせ結果は、userAndAlbumsWithTicket:finishedWithUserFeed:errorで受け
  // CoreDataへの登録を行う
  if([self mustLoad:self.user]) {
    // Network接続の確認
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self refreshAlbums];
  }
}


- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
	self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = NO;
  self.navigationController.toolbarHidden = NO; 
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.navigationItem.title = self.user.nickname;
}

 - (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if([self splitViewController] == nil) {
    PicasaViewerAppDelegate *delegate
    = (PicasaViewerAppDelegate *) [[UIApplication sharedApplication] delegate];
    if(delegate.photoListViewController) {
    }
  }
 }

#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(picasaFetchController) {
    [picasaFetchController release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    picasaFetchController = nil;
  }
  if(toolbarButtons) {
    [toolbarButtons release];
    toolbarButtons = nil;
  }
  if(backButton) {
    [backButton release];
    backButton = nil;
  }
  if(refreshButton) {
    [refreshButton release];
    refreshButton = nil;
  }
}

- (void)dealloc {
  NSLog(@"AlbumTableViewController deallloc");
  
  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(picasaFetchController) {
    [picasaFetchController release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    picasaFetchController = nil;
  }
  
  if(modelController)
    [modelController release];
  if(managedObjectContext)
    [managedObjectContext release];
  if(user)
    [user release];
  if(backButton)
    [backButton release];
  if(refreshButton)
    [refreshButton release];
  if(toolbarButtons)
    [toolbarButtons release];
  if(onLoadLock)
    [onLoadLock release];
  [super dealloc];
}


#pragma mark -

#pragma mark PicasaFetchControllerDelegate

// Googleへの問い合わせの応答の通知
// ローカルDBへの登録を行う.
- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL hasErrorInInserting = NO;
  BOOL hasErrorDeleting = NO;
  if(error) {
  }
  else {
    // ローカルDBへの保存
    NSLog(@"the user has %d alblums", [[feed entries] count]);
    // --  削除
    [modelController deleteAlbumsWithUserFeed:feed 
                          withUser:user 
                          hasError:&hasErrorDeleting];
    // -- 更新、新規
    if(hasErrorDeleting == NO) {
      [self insertOrUpdateAlbumsWithUserFeed:feed 
                                    withUser:user 
                                    hasError:&hasErrorInInserting];
    }
    [modelController setLastMod];
    // Album一覧のFetched Controllerを生成
    if(hasErrorInInserting || hasErrorDeleting) {
      NSString *message = nil;
      if(hasErrorDeleting) {
        message = NSLocalizedString(@"Error.Delete", @"Error IN Deleting");
      }
      else {
        message = NSLocalizedString(@"Error.Insert", @"Error IN Saving");
      }
      UIAlertView *alertView = [[UIAlertView alloc] 
                                initWithTitle:NSLocalizedString(@"Error", @"Error")
                                message:message
                                delegate:self 
                                cancelButtonTitle:@"OK" 
                                otherButtonTitles:nil];
      [alertView show];
      [alertView release];
    }
  }
  if (![[modelController fetchedAlbumsController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error","Error")
                              message:NSLocalizedString(@"Error.Fetch", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [pool drain];
    return;
  }
  // thumbnailをクリアしておく
  NSUInteger indexes[] = {0, 0};
  for(int i = 0; i < [self.tableView numberOfRowsInSection:0 ]  ; ++i) {
    indexes[1] = i;
    UITableViewCell *cell =  [self.tableView
                              cellForRowAtIndexPath:[NSIndexPath                                                                  indexPathWithIndexes:indexes length:2]];
    if(cell.imageView.image) {
      [cell.imageView setImage:nil];
    }
  }

  // Load中フラグをOffに
  [onLoadLock lock];
  onLoad = NO;
  [onLoadLock unlock];
  //
  [downloader start];
  [downloader finishQueuing];
  // そうじ
  [picasaFetchController release];
  picasaFetchController = nil;
  [pool drain];
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
  // Load中フラグをOff
	[onLoadLock lock];
  onLoad = NO;
  [onLoadLock unlock];
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  // toolbarのボタンをenable
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
  // Load中フラグをOff
	[onLoadLock lock];
  onLoad = NO;
  [onLoadLock unlock];
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
}

// Googleへの問い合わせの結果、エラーとなった場合の通知
- (void) PicasaFetchWasError:(NSError *)error {
  NSLog(@"connection error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"Error","Error");
  NSString *message = NSLocalizedString(@"Error.ConnectionToServer","Connection ERROR");
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
  // Load中フラグをOff
	[onLoadLock lock];
  onLoad = NO;
  [onLoadLock unlock];
  // Google接続コントローラーをclean
  [picasaFetchController release];
  picasaFetchController = nil;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[modelController.fetchedAlbumsController sections] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [modelController albumCount];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *CellIdentifier = 
  [@"Cell" stringByAppendingFormat:@"%d",[indexPath indexAtPosition:1 ] ];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
  }
  Album *managedObject = [modelController albumAt:[indexPath indexAtPosition:1]];
  cell.textLabel.text = [[managedObject valueForKey:@"title"] description];
  if(!cell.imageView.image) {
    // Configure the cell.
    Album *managedObject = (Album *)[modelController albumAt:[indexPath indexAtPosition:1]];
    if(managedObject.thumbnail) {
      UIImage *image = [[UIImage alloc] initWithData:managedObject.thumbnail];
      cell.imageView.image = image;
      [image release];
    }
    
  }
  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  // 一覧Load中であれば何もしない
  [onLoadLock lock];
  if(onLoad ) {
    [onLoadLock unlock];
    return;
  }
  [onLoadLock unlock];

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  // 選択行のAlbumのPhoto一覧へ
  Album *selectedObject = [modelController albumAt:[indexPath indexAtPosition:1]];
  PhotoListViewController *photoViewController
  = [self photoListViewControllerWithAlbum:(Album *) selectedObject] ;

  
    // Pass the selected object to the new view controller.
  if([self splitViewController] == nil) {
    [self.navigationController pushViewController:photoViewController animated:YES];
    
    NSLog(@"photoListViewController pushed. retain count = %d", [photoViewController retainCount]);
  }

  [pool drain];
  NSLog(@"photoListViewController pushed. retain count = %d", [photoViewController retainCount]);
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


#pragma mark UI Parts

- (UIBarButtonItem *)backButton {
  if(!backButton) {
    backButton = [[UIBarButtonItem alloc]
                  initWithTitle:NSLocalizedString(@"Accounts", @"Account")
                  style:UIBarButtonItemStyleDone
                  target:nil
                  action:nil ];
    
  }
  return backButton;
}

- (NSArray *) toolbarButtons {
  //NSString *path;
  
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
    UIBarButtonItem *spaceRight
    = [[UIBarButtonItem alloc]
       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
       target:self
       action:nil];
    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];
    [pool drain];
  }
  return toolbarButtons;
}

- (void) enableToolbar:(BOOL)enable {
  refreshButton.enabled = enable;
}

#pragma mark -

#pragma mark Private


- (void)insertOrUpdateAlbumsWithUserFeed:(GDataFeedPhotoUser *)feed
                                withUser:(User *)userObject 
                                hasError:(BOOL *)f {
  
  BOOL hasErrorInInserting = NO;
  
  NSArray *entries = [feed entries];
  for (int i = 0; i < [entries count]; ++i) {
    GDataEntryPhotoAlbum *album = [entries objectAtIndex:i];
    NSLog(@"album - title = %@, ident=%@, feedlink=%@",
          [[album title] contentStringValue], [album GPhotoID], [album feedLink]);
    BOOL hasError;
    Album *albumModel = [modelController selectAlbum:album 
                                            withUser:userObject 
                                            hasError:&hasError];
    if(hasError) {
      hasErrorInInserting = YES;
      continue;
    }
    if(albumModel) {
      albumModel = [modelController updateAlbum:albumModel 
                      withGDataAlbum:album withUser:userObject];
    }
    else {
      albumModel =  [modelController insertAlbum:album withUser:userObject];
    }
    if(albumModel) {
      [self downloadThumbnail:album withAlbumModel:albumModel];
    }
    else {
      hasErrorInInserting = YES;
    }
  }
	*f = hasErrorInInserting;
}	



- (void) downloadThumbnail:(GDataEntryPhotoAlbum *)album withAlbumModel:(Album *)model {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  if([[[album mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[album mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    NSString *urlForThumbnail = [thumbnail URLString];
    NSDictionary *dict = [[NSDictionary alloc] 
                          initWithObjectsAndKeys:model, @"album", nil] ;
    [downloader addURL:[NSURL URLWithString:urlForThumbnail ]
          withUserInfo:dict];
    [dict release];
  }
  [pool drain];
}


- (void) refreshAlbums {
  // Network接続の確認
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
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  // toolbarのボタンをdisable
  [self enableToolbar:NO];
  // Album一覧のロード処理を起動
  // clear fetchedController
  SettingsManager *settings = [[SettingsManager alloc] init];
  picasaFetchController = [[PicasaFetchController alloc] init];
  picasaFetchController.delegate = self;
  picasaFetchController.userId = settings.userId;
  picasaFetchController.password = settings.password;
  [picasaFetchController queryUserAndAlbums:self.user.userId];
  // Downloaderの準備
  downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:3];
  downloader.delegate = self;
  [settings release];
}

- (void) refreshTable {
  [(UITableView *)self.view reloadData];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
  [(UITableView *)self.view reloadData];
  
}


- (PhotoListViewController *)photoListViewControllerWithAlbum:(Album *)album {
  PhotoListViewController *photoViewController = nil;
  
  PicasaViewerAppDelegate *delegate
  = (PicasaViewerAppDelegate *) [[UIApplication sharedApplication] delegate];
  
  if([self splitViewController] == nil) {
    // iPhone
    photoViewController =[[[PhotoListViewController alloc]
                          initWithNibName:@"PhotoListViewController" bundle:nil]
                          autorelease];
    photoViewController.album = album;
    photoViewController.managedObjectContext = self.managedObjectContext;
    self.navigationItem.backBarButtonItem =  [photoViewController backButton];
    delegate.photoListViewController = photoViewController;
    // Pass the selected object to the new view controller.
  }
  else {
    // iPad
    photoViewController = delegate.photoListViewController;
    photoViewController.managedObjectContext = self.managedObjectContext;
    [photoViewController albumTableViewControll:self selectAlbum:album];
  }
  
  return photoViewController;
}

- (BOOL) mustLoad:(User *)curUser {
  if([modelController albumCount] == 0) {
    return YES;
  }

  
  if ( curUser.lastModAlbumAt == nil) {
    return YES;
  }
  if([self minutesBetween:curUser.lastModAlbumAt and:[NSDate date] ] > kIntervalForReloadWifi
      &&
      [NetworkReachability reachableByWifi]) {
    return YES;
  }

  SettingsManager *settings = [[SettingsManager alloc] init];
  NSDate *userLastModifiedAt = settings.userLastModifiedAt;
  [settings release];
  if(userLastModifiedAt != nil &&
     [self minutesBetween:curUser.lastModAlbumAt and:userLastModifiedAt ] > 0) {
    return YES;
  }
  BOOL ret = NO;
  // thumbnail の未ロードのものがないかのチェック
  for(int i = 0; i < [modelController albumCount]; ++i) {
    Album *albumModel = [modelController albumAt:i];
    if(albumModel == nil || albumModel.thumbnail == nil) {
      ret = YES;
      break;
    }
  }
  
  return ret;

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

#pragma mark -

#pragma mark QueuedURLDownloaderDelegate

- (void)didReceiveData:(NSData *)data withUserInfo:(NSDictionary *)info {
  NSLog(@"didReceiveData");
}

/*!
 ダウンロードエラー時の通知
 */
- (void)downloadDidFailWithError:(NSError *)error withUserInfo:(NSDictionary *)info {
  NSLog(@"downloadDidFailWithError");
  hasErrorInDownloading = YES;
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  NSLog(@"didFinishLoading");
  Album *model = (Album *)[info objectForKey:@"album"];
  if(model) {
    NSLog(@"updateThumbnail");
    if([modelController updateThumbnail:data forAlbum:model] == nil) {
      hasErrorInInsertingThumbnail = YES;
    }
    NSLog(@"updatedThumbnail");
  }
}

/*!
 すべてダウンロード完了時の通知
 */
- (void)didAllCompleted:(QueuedURLDownloader *)urlDownloader {
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
  
  // 表示をリフレッシュ
  [urlDownloader release];
  urlDownloader = nil;
  [self performSelectorOnMainThread:@selector(refreshTable)
                         withObject:nil
                      waitUntilDone:NO];
  [[NSRunLoop currentRunLoop] run];
}

/*!
 ダウンロードキャンセル時の通知
 */
- (void)dowloadCanceled:(QueuedURLDownloader *)urlDownloader {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
  [urlDownloader release];
  urlDownloader = nil;
}


#pragma mark -

#pragma mark Action

- (void) backAction:(id)sender {
  [self.navigationController popViewControllerAnimated:YES]; 
}

- (void) refreshAction:(id)sender {
  // Load中フラグをOnに
  [onLoadLock lock];
  onLoad = YES;
  [onLoadLock unlock];
  
  
	[self performSelectorOnMainThread:@selector(refreshAlbums) 
                         withObject:nil 
                      waitUntilDone:NO];
  
  
}  


#pragma mark -

#pragma mark Accessor to Property

- (void)setUser:(User *)newUser {

  if(user != newUser) {
	  user = newUser;
    [user retain];
  }
  SettingsManager *settings = [[SettingsManager alloc] init];
  [settings setCurrentUser:user.userId];
  [settings release];
  
}

#pragma mark -

@end

