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

@interface AlbumTableViewController(Private)

/*!
 @method insertAlbum
 @discussion Album情報をローカルDBに登録する.
 */
- (Album *)insertAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)user;
/*!
 @method updateThumbnail:forAlbum
 @discussion アルバムのThumbnailをローカルDBに更新登録する.
 */
- (Album *)updateThumbnail:(NSData *)thumbnailData forAlbum:(Album *)album;
/*!
 @method downloadThumbnail:withAlbumModel
 @discussion AlbumのThumbnailをダウンロードする.
 @param album Googleから取得したAlbum情報
 @param model ローカルDB上のAlbumのModelデータ
 */
- (void) downloadThumbnail:(GDataEntryPhotoAlbum *)album withAlbumModel:(Album *)model;



@end


@implementation AlbumTableViewController

@synthesize fetchedAlbumsController, managedObjectContext;
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
  
}


// View Load時の通知.Navigation BarのButtonの追加と
// Album一覧の取得を行う.ローカルDBにAlbumがなければGoogleへの問い合わせを起動する.
- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationItem.leftBarButtonItem = nil;
  
  NSError *error = nil;
  if (![[self fetchedAlbumsController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR","Error")
                              message:NSLocalizedString(@"ERROR_FETCH", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  // Albumが0件であれば、Googleへの問い合わせを起動.
  // 問い合わせ結果は、userAndAlbumsWithTicket:finishedWithUserFeed:errorで受け
  // CoreDataへの登録を行う
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedAlbumsController sections]
                                                  objectAtIndex:0];
  if([sectionInfo numberOfObjects] == 0) {
    //if([[fetchedAlbumsController sections] count] == 0) {
    [fetchedAlbumsController release];
    fetchedAlbumsController = nil;
    PicasaFetchController *controller = [[PicasaFetchController alloc] init];
    controller.delegate = self;
    [controller queryUserAndAlbums:self.user.userId];
    downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:3];
    downloader.delegate = self;
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
  if(error) {
    // Error
    NSString *title = NSLocalizedString(@"ERROR","Error");
    NSString *message = NSLocalizedString(@"ERROR_CON_SERVER","Error");
    if ([error code] == 404) {   // ユーザがいない
      title = NSLocalizedString(@"RESULT",@"Result");
      message = NSLocalizedString(@"WARN_NO_USER", @"No user");
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
    
  }
  // ローカルDBへの保存
  NSArray *entries = [feed entries];
  if ([entries count] > 0) {
    NSLog(@"the user has %d alblums", [[feed entries] count]);
    for (int i = 0; i < [entries count]; ++i) {
      GDataEntryPhotoAlbum *album = [entries objectAtIndex:i];
      NSLog(@"album - title = %@, ident=%@, feedlink=%@",
            [[album title] contentStringValue], [album GPhotoID], [album feedLink]);
      //  [self queryPhotoAlbum:[album GPhotoID] user:[album username]];
      Album *albumModel =  [self insertAlbum:album withUser:user];
      if(albumModel) {
        [self downloadThumbnail:album withAlbumModel:albumModel];
      }
      else {
        hasErrorInInserting = YES;
      }
    }
  }	
  // Album一覧のFetched Controllerを生成
  if(hasErrorInInserting) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR", @"Error")
                              message:NSLocalizedString(@"ERROR_INSERT", @"Error IN Saving")
                              delegate:self 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  if (![[self fetchedAlbumsController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR","Error")
                              message:NSLocalizedString(@"ERROR_FETCH", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    [pool drain];
    return;
  }
  // 表示をリフレッシュ
  [(UITableView *)self.view reloadData];
  //
  [downloader start];
  [downloader finishQueuing];
  [pool drain];
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if(!fetchedAlbumsController) {
    return 0;
  }
  return [[fetchedAlbumsController sections] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if(!fetchedAlbumsController) {
    return 0;
  }
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedAlbumsController sections]
                                                  objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *CellIdentifier = 
  [@"Cell" stringByAppendingFormat:@"%d",[indexPath indexAtPosition:1 ] ];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
    Album *managedObject = (Album *)[fetchedAlbumsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[managedObject valueForKey:@"title"] description];
  }
  if(!cell.imageView.image) {
    // Configure the cell.
    Album *managedObject = (Album *)[fetchedAlbumsController objectAtIndexPath:indexPath];
    if(managedObject.thumbnail) {
      UIImage *image = [[UIImage alloc] initWithData:managedObject.thumbnail];
      cell.imageView.image = image;
      [image release];
    }
    
  }
  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  PhotoListViewController *photoViewController = 
  [[PhotoListViewController alloc] initWithNibName:@"PhotoListViewController" bundle:nil];
  self.navigationItem.backBarButtonItem =  [photoViewController backButton];
  
  NSManagedObject *selectedObject = 
  [[self fetchedAlbumsController] objectAtIndexPath:indexPath];
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

#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedAlbumsController {
  
  if (fetchedAlbumsController != nil) {
    return fetchedAlbumsController;
  }
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"user.userId", user.userId];
  [fetchRequest setPredicate:predicate];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" 
                                                                 ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedAlbumsController = [[NSFetchedResultsController alloc] 
                                                          initWithFetchRequest:fetchRequest 
                                                          managedObjectContext:managedObjectContext 
                                                          sectionNameKeyPath:nil 
                                                          cacheName:@"Root"];
  aFetchedAlbumsController.delegate = self;
  self.fetchedAlbumsController = aFetchedAlbumsController;
  
  [aFetchedAlbumsController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  
  return fetchedAlbumsController;
}    




- (void)dealloc {
  NSLog(@"AlbumTableViewController deallloc");
  NSLog(@"managedObjectContext retain count = %d",[managedObjectContext retainCount]);
  NSLog(@"fetchedAlbumsController retain count = %d",[fetchedAlbumsController retainCount]);
  NSLog(@"user retain count = %d",[user retainCount]);
  NSLog(@"backButton retain count = %d",[backButton retainCount]);
  if(fetchedAlbumsController)
    [fetchedAlbumsController release];
  if(managedObjectContext)
    [managedObjectContext release];
  if(user)
    [user release];
  if(backButton)
    [backButton release];
  if(toolbarButtons) 
    [toolbarButtons release];
  [super dealloc];
}

#pragma mark Private
- (Album *)insertAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)user{
  NSString *albumId = [album GPhotoID];
  NSString *title = [[album title] contentStringValue];
  NSString *urlForThumbnail = nil;
  if([[[album mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[album mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    urlForThumbnail = [thumbnail URLString];
  }
  
  NSData *thumbnail = nil;
  // 新しい永続化オブジェクトを作って
  NSManagedObject *newManagedObject 
  = [NSEntityDescription insertNewObjectForEntityForName:@"Album"
                                  inManagedObjectContext:managedObjectContext];
  // 値を設定（If appropriate, configure the new managed object.）
  [newManagedObject setValue:albumId forKey:@"albumId"];
  [newManagedObject setValue:title forKey:@"title"];
  if(urlForThumbnail) {
    [newManagedObject setValue:urlForThumbnail forKey:@"urlForThumbnail"];
  }
  if(thumbnail) {
    [newManagedObject setValue:thumbnail forKey:@"thumbnail"];
  }
  [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
  // Save the context.
  NSError *error = nil;
  if ([self.user respondsToSelector:@selector(addAlbumObject:) ] ) {
    [self.user addAlbumObject:newManagedObject];
  }	
  if (![managedObjectContext save:&error]) {
    // 
    return nil;	
  }
  return (Album *)newManagedObject;
}

- (Album *)updateThumbnail:(NSData *)thumbnailData forAlbum:(Album *)album {
  if(!album)
    return nil;
  album.thumbnail = thumbnailData;
  NSError *error = nil;
  if (![managedObjectContext save:&error]) {
    // 
    NSLog(@"Unresolved error %@", error);
    hasErrorInInsertingThumbnail = YES;
    return nil;	
  }
  return album;
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

- (UIBarButtonItem *)backButton {
  if(!backButton) {
    backButton = [[UIBarButtonItem alloc] 
                  initWithTitle:NSLocalizedString(@"ACCOUNTS", @"Account")
                  style:UIBarButtonItemStyleDone 
                  target:nil
                  action:nil ];
    
  }
  return backButton;
}

- (NSArray *) toolbarButtons {
  NSString *path;
  
  if(!toolbarButtons) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    toolbarButtons = [[NSMutableArray alloc] init];
    // Info
    UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                             style:UIBarButtonItemStyleBordered 
                                                            target:self
                                                            action:nil];
    path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    info.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:info];
    [info release];
    
    // Space
    UIBarButtonItem *spaceRight
    = [[UIBarButtonItem alloc] 
       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
       target:self
       action:nil];
    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];
    
    // Setting
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] 
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                 target:self
                                 action:nil];
                                 
    path = [[NSBundle mainBundle] pathForResource:@"preferences" ofType:@"png"];
    settings.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:settings];
    [settings release];
    
    [pool drain];
  }
  return toolbarButtons;
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
    [self updateThumbnail:data forAlbum:model];
  }
}

/*!
 すべてダウンロード完了時の通知
 */
- (void)didAllCompleted {
  if(hasErrorInDownloading) {  // Thumbnail ダウンロードエラーがある場合.
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR", @"Error")
                              message:NSLocalizedString(@"ERROR_DOWNLOAD_THUMB", 
                                                        @"Error IN Downloading")
                              delegate:self 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  if(hasErrorInInsertingThumbnail) {  // Thumbnail 登録エラーがある場合.
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR", @"Error")
                              message:NSLocalizedString(@"ERROR_INSERT_THUMB", 
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
  [pool drain];
}


#pragma mark -

#pragma mark Action

- (void) backAction:(id)sender {
  [self.navigationController popViewControllerAnimated:YES]; 
}


#pragma mark -

@end

