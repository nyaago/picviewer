//
//  RootViewController.m
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
#import "RootViewController.h"
#import "AlbumTableViewController.h"
#import "NewUserViewController.h"
#import "SettingsViewController.h"
#import "GDataPhotos.h"
#import "User.h"
#import "Album.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"
#import "UserModelController.h"

@interface RootViewController(Private)

/*!
 @method addButtonAction:
 @discussion 追加ボタンのアクション,追加Viewを表示する
 */
- (void)addButtonAction:(id)sender;

/*!
 @method addButton
 @discussion addボタンを返す
 */
- (UIBarButtonItem *)addButton;

/*!
 @method insertNewUser:withNickname:
 @discussion 新規ユーザをデータベースに保存
 @param user user ID
 @param name ユーザーのニックネーム
 */
- (User *)insertNewUser:(NSString *)user withNickname:(NSString *)name;

/*!
 @method userWithUserId:
 @discussion 指定したユーザーIDのユーザーModelを返す
 */
- (User *)userWithUserId:(NSString *)uid;

/*!
 @method deleteUser:
 @discussion Userを削除
 */
- (void)deleteUser:(User *)user;

@end


@implementation RootViewController

@synthesize fetchedUsersController, managedObjectContext;

#pragma mark View lifecycle

- (void) loadView {
  [super loadView];
  CGRect frame = CGRectMake(0.0f, self.view.frame.size.height - 200.0f , 
                            self.view.frame.size.width, 200.0f);
  indicatorView = [[LabeledActivityIndicator alloc] initWithFrame:frame];
  [indicatorView setMessage:NSLocalizedString(@"Root.Deleting", "on deleting")];
  
  firstAppearance = YES;
}

// Viewロード時の通知.
// Navigation Bar のボタンの追加とUserデータのFetched Controllerの生成.
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Title
  self.navigationItem.title = NSLocalizedString(@"Acounts.Title", @"Acounts");

  // Set up the edit and add buttons.
  self.navigationItem.leftBarButtonItem = self.editButtonItem;
  self.navigationItem.rightBarButtonItem = [self addButton];
  
  NSError *error = nil;
  if (![[self fetchedUsersController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error",@"Error")
                              message:NSLocalizedString(@"Error.Fetch", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
  }
  
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbarHidden = NO; 
  
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  SettingsManager *settings = [[SettingsManager alloc] init];
  NSString *userId = [settings currentUser];
  // 最初の表示、user選択済みの場合はAlbum一覧へ
  if(firstAppearance) {
    if(settings.userId != nil && settings.username == nil) {
      // user id が設定されているけど,usernameが設定されていない(username が
      // 追加されて後の最初の起動) => 強制的に設定へ
      [settings release];
      [self settingsAction:self];
      return;
    }
    if(userId) {
      //	  User *user = [self selectUser:userId];
      User *user = [self userWithUserId:userId];
      if(user) {
        AlbumTableViewController *albumViewController =
        [[AlbumTableViewController alloc] initWithNibName:@"AlbumTableViewController"
                                                   bundle:nil];
        self.navigationItem.backBarButtonItem =  [albumViewController backButton];
        albumViewController.managedObjectContext = self.managedObjectContext;
        albumViewController.user = user;
        // Pass the selected object to the new view controller.
        [self.navigationController pushViewController:albumViewController animated:YES];
        [albumViewController release];
      }
    }
    else {
      [settings setCurrentUser:nil];
    }
    firstAppearance = NO;
  }
  [settings release];
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

#pragma mark Model Handling

- (User *)insertNewUser:(NSString *)user withNickname:(NSString *)name{
  // Create a new instance of the entity managed by the fetched results controller.
  NSManagedObjectContext *context = [fetchedUsersController managedObjectContext];
  NSEntityDescription *entity = [[fetchedUsersController fetchRequest] entity];
  NSManagedObject *newManagedObject = [NSEntityDescription 
                                       insertNewObjectForEntityForName:[entity name] 
                                       inManagedObjectContext:context];
  
  // If appropriate, configure the new managed object.
  [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
  [newManagedObject setValue:user forKey:@"userId"];
  [newManagedObject setValue:name forKey:@"nickname"];
  
  // Save the context.
  NSError *error = nil;
  if (![context save:&error]) {
    // Error
    NSLog(@"Unresolved error %@", error);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error","Error")
                              message:NSLocalizedString(@"Error.Insert", 
                                                        @"Error in adding")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
    return nil;
  }
  return (User *)newManagedObject;
}


- (void)deleteUser:(User *)user {

  self.tableView.userInteractionEnabled = NO;
  UserModelController *modelController = [[UserModelController alloc] initWithContext:self.managedObjectContext];
  [modelController deleteUser:user];
/*
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error","Error")
                              message:NSLocalizedString(@"Error.Delete", 
                                                        @"Error in deleting")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
 */
//  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
//  [self.tableView reloadData];
}

- (User *)userWithUserId:(NSString *)uid {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedUsersController sections]
                                                  objectAtIndex:0];
  NSInteger n =  [sectionInfo numberOfObjects];
  
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = 0;
  for(int i = 0; i < n; ++i) {
    indexes[1] = i;
    NSManagedObject *object =
    [fetchedUsersController objectAtIndexPath:[NSIndexPath
                                               indexPathWithIndexes:indexes length:2]];
    User *user = (User *)object;
    if([user.userId isEqual:uid] ) {
      return user;
    }
  }
  return nil;
}

#pragma mark -

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[fetchedUsersController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedUsersController sections] 
                                                  objectAtIndex:section];
  return [sectionInfo numberOfObjects];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  NSString *CellIdentifier = 
  [@"Cell" stringByAppendingFormat:@"%d",[indexPath indexAtPosition:1 ] ];
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
    // Configure the cell.
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  NSManagedObject *managedObject = [fetchedUsersController objectAtIndexPath:indexPath];
  cell.textLabel.text = [[managedObject valueForKey:@"nickname"] description];
  return cell;
}

// tableのCell選択時の通知.
// Album一覧Viewを表示する.
- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  AlbumTableViewController *albumViewController = 
	[[AlbumTableViewController alloc] initWithNibName:@"AlbumTableViewController" 
                                             bundle:nil];
  self.navigationItem.backBarButtonItem =  [albumViewController backButton];
  NSManagedObject *selectedObject = 
  [[self fetchedUsersController] objectAtIndexPath:indexPath];
  albumViewController.managedObjectContext = self.managedObjectContext;
  albumViewController.user = (User *)selectedObject;
  // Pass the selected object to the new view controller.
  [self.navigationController pushViewController:albumViewController animated:YES];
  [albumViewController release];
  
}


// Override to support editing the table view.
// 選択されているUserの削除を行う.
- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    User *user = [fetchedUsersController objectAtIndexPath:indexPath];

    SettingsManager *settings = [[SettingsManager alloc] init];
    NSString *userId = [settings currentUser];
    
    if(user.userId == userId) {
      PicasaViewerAppDelegate *appDelegate
      = (PicasaViewerAppDelegate *)[[UIApplication sharedApplication] delegate];
      if(appDelegate.photoListViewController != nil) {
        [appDelegate.photoListViewController discardTumbnails];
      }
      [settings setCurrentUser:nil];
    }
    [settings release];
    
    // indicator View を表示して、Background threadで削除処理の起動、
  	[self.view addSubview:indicatorView];
    [indicatorView startWithTarget:self
                      withSelector:@selector(deleteUser:) 
                        withObject:user];
    
  }   
}

// 
- (BOOL)tableView:(UITableView *)tableView 
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  // The table view should not be re-orderable.
  return NO;
}


#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedUsersController {
  
  if (fetchedUsersController != nil) {
    return fetchedUsersController;
  }
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" 
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] 
                                      initWithKey:@"timeStamp" ascending:YES];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedUsersController = [[NSFetchedResultsController alloc] 
                                                         initWithFetchRequest:fetchRequest 
                                                         managedObjectContext:managedObjectContext 
                                                         sectionNameKeyPath:nil 
                                                         cacheName:@"Root"];
  aFetchedUsersController.delegate = self;
  self.fetchedUsersController = aFetchedUsersController;
  
  [aFetchedUsersController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  
  return fetchedUsersController;
}    


// NSFetchedResultsControllerDelegate method to notify the delegate 
// that all section and object changes have been processed. 
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
  // In the simplest, most efficient, case, reload the table view.
  [self.tableView reloadData];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Relinquish ownership of any cached data, images, etc that aren't in use.
  [addButton release];
  addButton = nil;
  [toolbarButtons release];
  toolbarButtons = nil;
}


- (void)dealloc {
  if(fetchedUsersController)
    [fetchedUsersController release];
  if(managedObjectContext)
    [managedObjectContext release];
  if(addButton)
    [addButton release];
  if(toolbarButtons)
    [toolbarButtons release];
  if(indicatorView) {
    [indicatorView release];
  }
  [super dealloc];
}
#pragma mark -

#pragma mark UI parts

- (UIBarButtonItem *)addButton {
  if(!addButton) {
    addButton = [[UIBarButtonItem alloc] 
                 initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                 target:self 
                 action:@selector(addButtonAction:)];
  }
  return addButton;
}

- (NSArray *) toolbarButtons {
  NSString *path;
  
  if(!toolbarButtons) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    toolbarButtons = [[NSMutableArray alloc] init];
    
    // Space
    UIBarButtonItem *spaceRight =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
     target:self
     action:nil];
    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];
    
    // Setting
    UIBarButtonItem *settings = [[UIBarButtonItem alloc]
                                 initWithTitle:@""
                                 style:UIBarButtonItemStyleBordered
                                 target:self
                                 action:@selector(settingsAction:)];
    path = [[NSBundle mainBundle] pathForResource:@"preferences" ofType:@"png"];
    settings.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:settings];
    [settings release];
    
    [pool drain];
  }
  return toolbarButtons;
}


#pragma mark -


#pragma mark NewUserViewControllerDelegate

- (BOOL) doneWithNewUser:(NSString *)user {
  // Network接続確認
  if(![NetworkReachability reachable]) {
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Warn", @"warn")
                              message:NSLocalizedString(@"Warn.NetworkNotReachable",
                                                        @"network not reachable")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    return NO;
  }
  [self dismissModalViewControllerAnimated:YES];

  PicasaFetchController *controller = [[PicasaFetchController alloc] init];
  controller.delegate = self;
  [controller queryUserAndAlbums:user];
  return YES;
}

#pragma mark -

#pragma mark PicasaFetchControllerDelegate

- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error {
  if(error) {
    return;
  }
//  NSLog(@"user = %@", [feed GPhotoID]);
//  NSLog(@"user name = %@, %@", [feed username],   [feed description]);
//  NSLog(@"authers = %@",[[feed authors] objectAtIndex:0]);

  User *user = [self insertNewUser:[feed username] withNickname:[feed nickname]];
  if(!user) {
    return ;
  }
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  [fetchedUsersController release];
  fetchedUsersController = nil;
  if (![[self fetchedUsersController] performFetch:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"Error",@"Error")
                              message:NSLocalizedString(@"Error.Fetch", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
  }
  [(UITableView *)self.view reloadData];
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
  [self dismissModalViewControllerAnimated:YES];
}

// Googleへの問い合わせの結果、指定ユーザがなかった場合の通知
- (void) PicasaFetchNoUser:(NSError *)error {
  NSLog(@"no user");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"WARN","WARN");
  NSString *message = NSLocalizedString(@"Warn.NoUser","NO USER");
  if ([error code] == 404) {
    title = NSLocalizedString(@"Result",@"Result");
    message = NSLocalizedString(@"Warn.NoUser", @"No user");
  }
  UIAlertView *alertView = [[UIAlertView alloc]
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK" 
                            otherButtonTitles:nil];
  [alertView show];
  [alertView release];
  [pool drain];
}

// Googleへの問い合わせの結果、エラーとなった場合の通知
- (void) PicasaFetchWasError:(NSError *)error {
  NSLog(@"connection error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"Error",@"Error");
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
}

#pragma mark -

#pragma mark Action

- (void) settingsAction:(id)sender {
  SettingsViewController *viewController = [[SettingsViewController alloc] 
                                           initWithNibName:@"SettingsViewController" 
                                           bundle:nil];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
  [self presentModalViewController:navigationController animated:YES];
  [viewController release];
  [navigationController release];
}

- (void)addButtonAction:(id)sender {
  self.editing = NO;
  NSString *nibName = nil;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    nibName = @"NewUserViewController-iPad";
  }
  else {
    nibName = @"NewUserViewController";
  }
  
  NewUserViewController *controller = [[NewUserViewController alloc]
                                       initWithNibName:nibName
                                       bundle:nil];
  controller.delegate = self;
  [controller setModalPresentationStyle:UIModalPresentationFormSheet];
  [self presentModalViewController:controller animated:YES];
}


#pragma mark LabeledActivityIndicatorDelegate

- (void)indicatorStoped:(LabeledActivityIndicator *)view {
  [view removeFromSuperview];
  self.tableView.userInteractionEnabled = YES;
}

#pragma mark -

@end

