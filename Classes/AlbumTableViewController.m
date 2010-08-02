//
//  AlbumTableViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AlbumTableViewController.h"
#import "PhotoListViewController.h"
#import "Album.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

@interface AlbumTableViewController(Private)



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
 @method enableToolbar:
 @discussion toolbarのButtonの有効無効の切り替え
 */
- (void) enableToolbar:(BOOL)enable;

- (void)insertOrUpdateAlbumsWithUserFeed:(GDataFeedPhotoUser *)album 
                                withUser:(User *)userObject
                                hasError:(BOOL *)f;

@end


@implementation AlbumTableViewController

@synthesize managedObjectContext;
@synthesize user;

#pragma mark View lifecycle

/*
 - (id)initWithStyle:(UITableViewStyle)style {
 // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
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
  if([modelController albumCount] == 0) {
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
    // toolbarのボタンをdisable
    [self enableToolbar:NO];
    // reload
    SettingsManager *settings = [[SettingsManager alloc] init];
    picasaFetchController = [[PicasaFetchController alloc] init];
    picasaFetchController.delegate = self;
    picasaFetchController.userId = settings.userId;
    picasaFetchController.password = settings.password;
    [picasaFetchController queryUserAndAlbums:self.user.userId];
    downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:3];
    downloader.delegate = self;
    [settings release];
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
  self.navigationItem.title = self.user.userId;
}

/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
  
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
  // table の再表示
  [(UITableView *)self.view reloadData];
  // Load中フラグをOffに
  [onLoadLock lock];
  onLoad = NO;
  [onLoadLock unlock];
  //
  [downloader start];
  [downloader finishQueuing];
  // そうじ
  [picasaFetchController release];
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
  Album *managedObject = [modelController albumAt:indexPath];
  cell.textLabel.text = [[managedObject valueForKey:@"title"] description];
  if(!cell.imageView.image) {
    // Configure the cell.
    Album *managedObject = (Album *)[modelController albumAt:indexPath];
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
  // 選択行のAlbumのPhoto一覧へ
  PhotoListViewController *photoViewController = 
  [[PhotoListViewController alloc] initWithNibName:@"PhotoListViewController" bundle:nil];
  self.navigationItem.backBarButtonItem =  [photoViewController backButton];
  
  Album *selectedObject = [modelController albumAt:indexPath];
  photoViewController.managedObjectContext = self.managedObjectContext;
  photoViewController.album = (Album *)selectedObject;
  // Pass the selected object to the new view controller.
  [self.navigationController pushViewController:photoViewController animated:YES];
  [photoViewController release];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView 
 canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView 
 commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
 forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, 
 and add a new row to the table view
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView 
 moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */



- (void)dealloc {
  NSLog(@"AlbumTableViewController deallloc");
  NSLog(@"managedObjectContext retain count = %d",[managedObjectContext retainCount]);
  NSLog(@"user retain count = %d",[user retainCount]);
  NSLog(@"backButton retain count = %d",[backButton retainCount]);

  // 一覧ロード中であれば、停止要求をして、停止するまで待つ
  if(picasaFetchController) {
    [picasaFetchController release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    picasaFetchController = nil;
  }
  
  // ダウンロード中であれば、ダウンロード停止要求をして、停止するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [downloader release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    downloader = nil;
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
    //  [self queryPhotoAlbum:[album GPhotoID] user:[album username]];
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
  	/*  
     // Info
     UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithTitle:@"" 
     style:UIBarButtonItemStyleBordered 
     target:self
     action:nil];
     path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    info.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:info];
    [info release];
    */
    [pool drain];
  }
  return toolbarButtons;
}

- (void) enableToolbar:(BOOL)enable {
  refreshButton.enabled = enable;
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
  Album *model = (Album *)[info objectForKey:@"album"];
  if(model) {
    if([modelController updateThumbnail:data forAlbum:model] == nil) {
      hasErrorInInsertingThumbnail = YES;
    }
  }
}

/*!
 すべてダウンロード完了時の通知
 */
- (void)didAllCompleted {
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
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [(UITableView *)self.view reloadData];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
  // downloaderのそうじ
  [downloader release];
  downloader = nil;

  [pool drain];
}

/*!
 ダウンロードキャンセル時の通知
 */
- (void)dowloadCanceled {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  // toolbarのボタンをenable
  [self enableToolbar:YES];
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
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[self performSelectorOnMainThread:@selector(refreshAlbums) 
                         withObject:nil 
                      waitUntilDone:NO];
  
  
}  


#pragma mark -

- (void)setUser:(User *)newUser {

  if(user != newUser) {
	  user = newUser;
    [user retain];
  }
  SettingsManager *settings = [[SettingsManager alloc] init];
  [settings setCurrentUser:user.userId];
  [settings release];
  
}


@end

