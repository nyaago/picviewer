//
//  RootViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RootViewController.h"
#import "AlbumTableViewController.h"
#import "NewUserViewController.h"
#import "SettingsViewController.h"
#import "GDataPhotos.h"
#import "User.h"
#import "Album.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

@interface RootViewController(Private)

/*!
 追加ボタンのアクション,追加Viewを表示する
 */
- (void)addButtonAction:(id)sender;

/*!
 addボタンを返す
 */
- (UIBarButtonItem *)addButton;

/*!
 新規ユーザをデータベースに保存
 */
- (User *)insertNewUser:(NSString *)user withNickname:(NSString *)name;


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
}

// Viewロード時の通知.
// Navigation Bar のボタンの追加とUserデータのFetched Controllerの生成.
- (void)viewDidLoad {
  [super viewDidLoad];
//  self.view.backgroundColor = [UIColor blackColor];
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
  SettingsManager *settings = [[SettingsManager alloc] init];
  NSString *userId = [settings currentUser];
  if(userId) {
    //	  User *user = [self selectUser:userId];
    User *user = [self userWithUserId:userId];
    if(user) {
      AlbumTableViewController *albumViewController = 
      [[AlbumTableViewController alloc] initWithNibName:@"AlbumTableViewController" 
                                                 bundle:nil];
      //  AlbumTableViewController *albumViewController = 
      //  [[AlbumTableViewController alloc] init];
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
  [settings release];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbarHidden = NO; 
  
}


- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
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

- (void)viewDidUnload {
  // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
  // For example: self.myOutlet = nil;
  SettingsManager *settings = [[SettingsManager alloc] init];
  [settings setCurrentUser:nil];
  [settings release];

}


#pragma mark -

#pragma mark Add a new object / delete object

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

  [managedObjectContext deleteObject:user];
  // Save the context.
  NSError *error = nil;
  if (![managedObjectContext save:&error]) {
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
  }
  [self.tableView reloadData];

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
    // indicator View を表示して、Background threadで削除処理の起動、
  	[self.view addSubview:indicatorView];
    User *user = [fetchedUsersController objectAtIndexPath:indexPath];
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
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Relinquish ownership of any cached data, images, etc that aren't in use.
}


- (void)dealloc {
  [fetchedUsersController release];
  [managedObjectContext release];
  [addButton release];
  [toolbarButtons release];
  if(indicatorView) {
    [indicatorView release];
  }
  [super dealloc];
}
#pragma mark -

#pragma mark Memory management

- (UIBarButtonItem *)addButton {
  if(!addButton) {
    addButton = [[UIBarButtonItem alloc] 
                 initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                 target:self 
                 action:@selector(addButtonAction:)];
  }
  return addButton;
}
#pragma mark -

#pragma mark Action

- (void)addButtonAction:(id)sender {
  self.editing = NO;
  NewUserViewController *controller = [[NewUserViewController alloc] 
                                       initWithNibName:@"NewUserViewController" 
                                       bundle:nil];
  controller.delegate = self;
  [self presentModalViewController:controller animated:YES];
}

#pragma mark -

#pragma mark NewUserViewControllerDelegate

- (BOOL) doneWithNewUser:(NSString *)user {
  // Network接続確認
  if(![NetworkReachability reachable]) {
    return YES;
  }
  
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
    NSString *title = NSLocalizedString(@"Error","Error");
    NSString *message = NSLocalizedString(@"Error.ConnectionToServer","Error");
    if ([error code] == 404) {
      title = NSLocalizedString(@"Result",@"Result");
      message = NSLocalizedString(@"Warn.NoUser", @"No user");
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
  NSLog(@"user name = %@", [feed username]);
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
  [self dismissModalViewControllerAnimated:YES];
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
  [self dismissModalViewControllerAnimated:YES];
}


#pragma mark Action

- (void) settingsAction:(id)sender {
  SettingsViewController *viewController = [[SettingsViewController alloc] 
                                           initWithNibName:@"SettingsViewController" 
                                           bundle:nil];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  [self.view.window bringSubviewToFront:self.view];
  [self presentModalViewController:navigationController animated:YES];
  [viewController release];
  [navigationController release];
}

#pragma mark LabeledActivityIndicatorDelegate

- (void)indicatorStoped:(LabeledActivityIndicator *)view {
  [view removeFromSuperview];
}

#pragma mark -

#pragma mark -

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

@end

