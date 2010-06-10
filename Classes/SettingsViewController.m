//
//  SettingsViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/05/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"


@implementation SettingsViewController

#pragma mark View Lifecycle

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically 
 		// and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*!
 @method viewDidLad
 @discussion View Load時の通知.navigationBarの設定、設定情報管理Objectの生成
 */
- (void)viewDidLoad {
  [super viewDidLoad];
  // navigationBar
	completeButton = [[UIBarButtonItem alloc] 
                    initWithBarButtonSystemItem:UIBarButtonSystemItemDone                    
                    target:self 
                    action:@selector(completeAction:) ];
	self.navigationItem.rightBarButtonItem = completeButton;
  // 設定情報管理オブジェクト
  settings = [[SettingsManager alloc] init];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

/*!
 @method viewDidAppear:
 @discussion View表示後の通知
 */
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
	[super viewDidUnload];
  [completeButton release];
  completeButton = nil;
  [settings release];
  settings = nil;
  [userTextField release];
  userTextField = nil;
  [passwordTextField release];
  passwordTextField = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case(0) :
      return 2;
    default:
      return 0;
  }
}


/*!
 各セクションのタイトルを返す
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case(0) :
      return NSLocalizedString(@"SECTION_ACCOUNT", @"Acount");
    default:
      return @"";
  }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
    CGRect frame =  CGRectMake(100.0f, 5.0f, 
                               cell.frame.size.width - 120.0f , 
                               cell.frame.size.height - 10.0f);
    switch ([indexPath indexAtPosition:0]) {
      case(0) : // アカウントの設定
        switch ([indexPath indexAtPosition:1]) {
          case (0):
            cell.textLabel.text = NSLocalizedString(@"CAPTION_USER",@"User");
            frame =  CGRectMake(120.0f, 10.0f, 
                                cell.frame.size.width - 120.0f , 
                                cell.frame.size.height - 20.0f);
            userTextField = [[UITextField alloc] initWithFrame:frame];
            [userTextField addTarget:self 
                         action:@selector(userDidEndEditing:) 
               forControlEvents:UIControlEventEditingDidEndOnExit];
            userTextField.text = settings.userId;
            [cell addSubview:userTextField];
            break;
          case (1):
            cell.textLabel.text = NSLocalizedString(@"CAPTION_PASSWORD",@"Password");
            frame =  CGRectMake(120.0f, 10.0f, 
                                cell.frame.size.width - 120.0f , 
                                cell.frame.size.height - 20.0f);
            passwordTextField = [[UITextField alloc] initWithFrame:frame];
            [passwordTextField setSecureTextEntry:YES];
            [passwordTextField addTarget:self 
                         action:@selector(passwordDidEndEditing:) 
               forControlEvents:UIControlEventEditingDidEndOnExit];
            passwordTextField.text = settings.password;
            [cell addSubview:passwordTextField];
            break;
       }
    }
  }
  
  return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch ([indexPath indexAtPosition:0]) {
    case(0) : // アカウント
      switch ([indexPath indexAtPosition:1]) {
        case (0): // ユーザ名
          break;
        case (1): // パスワード
          break;
      }
  }
  
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark action

- (void) completeAction:(id)sender {
  settings.userId = userTextField.text;
  settings.password = passwordTextField.text;
  
  PicasaFetchController *controller = [[PicasaFetchController alloc] init];
  controller.delegate = self;
  controller.userId = settings.userId;
  controller.password = settings.password;
  [controller queryUserAndAlbums:settings.userId];
}

- (void) userDidEndEditing:(id)sender {
  UITextField *textField = (UITextField *)sender;
  settings.userId = textField.text;
}

- (void) passwordDidEndEditing:(id)sender {
  UITextField *textField = (UITextField *)sender;
  settings.password = textField.text;
}

#pragma mark PicasaFetchControllerDelegate

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
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


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
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


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
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


- (void)userAndAlbumsWithTicket:(GDataServiceTicket *)ticket
           finishedWithUserFeed:(GDataFeedPhotoUser *)feed
                          error:(NSError *)error {
  NSLog(@"user and album");
  [self.parentViewController dismissModalViewControllerAnimated:YES];

}



#pragma mark -

- (void)dealloc {
  if(completeButton)
    [completeButton release];
  if(settings) 
    [settings release];
  if(userTextField)
    [userTextField release];
  if(passwordTextField) 
    [passwordTextField release];
  [super dealloc];
}


@end

