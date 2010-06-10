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
- (User *)insertNewUser:(NSString *)user;


- (User *)userWithUserId:(NSString *)uid;

@end


@implementation RootViewController

@synthesize fetchedUsersController, managedObjectContext;

#pragma mark View lifecycle

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
                              initWithTitle:NSLocalizedString(@"ERROR","Error")
                              message:NSLocalizedString(@"ERROR_FETCH", @"Error in ng")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK"];
    [alertView show];
    [alertView release];
  }
  SettingsManager *settings = [[SettingsManager alloc] init];
  NSString *userId = [settings currentUser];
  if(userId) {
    //	  User *user = [self selectUser:userId];
    User *user = [self userWithUserId:userId];
    AlbumTableViewController *albumViewController = 
    [[AlbumTableViewController alloc] initWithNibName:@"AlbumTableViewController" bundle:nil];
    //  AlbumTableViewController *albumViewController = 
    //  [[AlbumTableViewController alloc] init];
    self.navigationItem.backBarButtonItem =  [albumViewController backButton];
    albumViewController.managedObjectContext = self.managedObjectContext;
    albumViewController.user = user;
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:albumViewController animated:YES];
    [albumViewController release];
    
  }
  [settings setCurrentUser:nil];
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

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


#pragma mark -
#pragma mark Add a new object

- (User *)insertNewUser:(NSString *)user {
  // Create a new instance of the entity managed by the fetched results controller.
  NSManagedObjectContext *context = [fetchedUsersController managedObjectContext];
  NSEntityDescription *entity = [[fetchedUsersController fetchRequest] entity];
  NSManagedObject *newManagedObject = [NSEntityDescription 
                                       insertNewObjectForEntityForName:[entity name] 
                                       inManagedObjectContext:context];
  
  // If appropriate, configure the new managed object.
  [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
  [newManagedObject setValue:user forKey:@"userId"];
  
  // Save the context.
  NSError *error = nil;
  if (![context save:&error]) {
    // Error
    NSLog(@"Unresolved error %@", error);
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR","Error")
                              message:NSLocalizedString(@"ERROR_INSERT", @"Error in adding")
                              delegate:nil
                              cancelButtonTitle:nil 
                              otherButtonTitles:@"OK"];
    [alertView show];
    [alertView release];
    return nil;
  }
  return (User *)newManagedObject;
}

#pragma mark -

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [[fetchedUsersController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedUsersController sections] objectAtIndex:section];
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
    // Configure the cell.
    NSManagedObject *managedObject = [fetchedUsersController objectAtIndexPath:indexPath];
    cell.textLabel.text = [[managedObject valueForKey:@"userId"] description];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  return cell;
}

// tableのCell選択時の通知.
// Album一覧Viewを表示する.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  AlbumTableViewController *albumViewController = 
	[[AlbumTableViewController alloc] initWithNibName:@"AlbumTableViewController" bundle:nil];
  //  AlbumTableViewController *albumViewController = 
  //  [[AlbumTableViewController alloc] init];
  self.navigationItem.backBarButtonItem =  [albumViewController backButton];
  NSManagedObject *selectedObject = 
  [[self fetchedUsersController] objectAtIndexPath:indexPath];
  albumViewController.managedObjectContext = self.managedObjectContext;
  albumViewController.user = (User *)selectedObject;
  // Pass the selected object to the new view controller.
  [self.navigationController pushViewController:albumViewController animated:YES];
  [albumViewController release];
  
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

// Override to support editing the table view.
// 選択されているUserの削除を行う.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the managed object for the given index path
    NSManagedObjectContext *context = [fetchedUsersController managedObjectContext];
    [context deleteObject:[fetchedUsersController objectAtIndexPath:indexPath]];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      UIAlertView *alertView = [[UIAlertView alloc] 
                                initWithTitle:NSLocalizedString(@"ERROR","Error")
                                message:NSLocalizedString(@"ERROR_DELETE", @"Error in deleting")
                                delegate:nil
                                cancelButtonTitle:nil 
                                otherButtonTitles:@"OK"];
      [alertView show];
      [alertView release];
    }
  }   
}

// 
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
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
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedUsersController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
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

/*
 Instead of using controllerDidChangeContent: to respond to all changes, 
 you can implement all the delegate methods 
 to update the table view in response to individual changes.  
 This may have performance implications if a large number of changes are made simultaneously.
 
 // Notifies the delegate that section and object changes are about to be processed 
 and notifications will be sent. 
 - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
 [self.tableView beginUpdates];
 }
 
 - (void)controller:(NSFetchedResultsController *)controller 
 didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
 atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
 // Update the table view appropriately.
 }
 
 - (void)controller:(NSFetchedResultsController *)controller 
 didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath 
 forChangeType:(NSFetchedResultsChangeType)type 
 newIndexPath:(NSIndexPath *)newIndexPath {
 // Update the table view appropriately.
 }
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
 [self.tableView endUpdates];
 } 
 */



- (User *)userWithUserId:(NSString *)uid {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedUsersController sections] 
                                                  objectAtIndex:0];
  NSInteger n =  [sectionInfo numberOfObjects];

  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = 0;
  for(int i = 0; i < n; ++i) {
    indexes[1] = i;
    NSManagedObject *object = [fetchedUsersController objectAtIndexPath:[NSIndexPath 
                                                                          indexPathWithIndexes:indexes length:2]];
    User *user = (User *)object;
    if([user.userId isEqual:uid] ) {
      return user;
    }
    return nil;
  }    
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
    NSString *title = NSLocalizedString(@"ERROR","Error");
    NSString *message = NSLocalizedString(@"ERROR_CON_SERVER","Error");
    if ([error code] == 404) {
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
  User *user = [self insertNewUser:[feed username]];
  if(!user) {
    return ;
  }
  
  [(UITableView *)self.view reloadData];
  [self dismissModalViewControllerAnimated:YES];
}

// Googleへの問い合わせの結果、認証エラーとなった場合の通知
- (void) PicasaFetchWasAuthError:(NSError *)error {
  NSLog(@"auth error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"ERROR","Error");
  NSString *message = NSLocalizedString(@"ERROR_AUTH","AUTH ERROR");
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
  NSString *message = NSLocalizedString(@"WARN_NO_USER","NO USER");
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
  NSString *title = NSLocalizedString(@"ERROR","Error");
  NSString *message = NSLocalizedString(@"ERROR_CON_SERVER","Connection ERROR");
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



#pragma mark -

- (NSArray *) toolbarButtons {
  NSString *path;
  
  if(!toolbarButtons) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    toolbarButtons = [[NSMutableArray alloc] init];
    // Info
    /*
    UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                             style:UIBarButtonItemStyleBordered 
                                                            target:self
                                                            action:nil];
    path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    info.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:info];
    [info release];
    */
    // Space
    UIBarButtonItem *spaceRight = [[UIBarButtonItem alloc] 
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

