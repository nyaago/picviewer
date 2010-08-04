//
//  SettingsViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/05/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "NetworkReachability.h"

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
  // Title
  self.navigationController.title = NSLocalizedString(@"Settings.Title", 
                                                      @"Settings");
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
  [sizeControl release];
  sizeControl = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
  switch (section) {
    case(0) :
      return 2;
    case(1) :
      return 1;
    default:
      return 0;
  }
}


/*!
 @method tableView:titleForHeaderInSection:
 @discussion 各セクションのタイトルを返す
 */
- (NSString *)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section {
  switch (section) {
    case(0) :
      return NSLocalizedString(@"Settings.Account", @"Acount");
    case(1) :
      return NSLocalizedString(@"Settings.Image", @"Image");
    default:
      return @"";
  }
}

/*!
 @method tableView:cellForRowAtIndexPath:
 @discussion 各Cellオブジェクトを返す
 */
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
            cell.textLabel.text = NSLocalizedString(@"Settings.Account.User"
                                                    ,@"User");
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
            cell.textLabel.text = NSLocalizedString(@"Settings.Account.Password",
                                                    @"Password");
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
        break;
      case(1) : // アカウントの設定
        switch ([indexPath indexAtPosition:1]) {
          case (0):
            cell.textLabel.text = NSLocalizedString(@"Settings.Image.Size"
                                                    ,@"Size");
            frame =  CGRectMake(90.0f, 10.0f, 
                                cell.frame.size.width - (90.0f + 20.0f) , 
                                cell.frame.size.height - 20.0f);
          	
            sizeControl = [[UISegmentedControl alloc] initWithFrame:frame];
            [sizeControl insertSegmentWithTitle:@"640" 
                                        atIndex:0 
                                       animated:NO];
            [sizeControl insertSegmentWithTitle:@"1280" 
                                        atIndex:1
                                       animated:NO];
            [sizeControl insertSegmentWithTitle:@"1600" 
                                        atIndex:2 
                                       animated:NO];
            sizeControl.selectedSegmentIndex = [SettingsManager 
                                                imageSizeToIndex:settings.imageSize];
            [cell addSubview:sizeControl];
            break;
        }
            
    }
  }
  
  return cell;
}


- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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


#pragma mark action

- (void) completeAction:(id)sender {
  settings.userId = userTextField.text;
  settings.password = passwordTextField.text;
  settings.imageSize = [SettingsManager 
                        indexToImageSize:sizeControl.selectedSegmentIndex];
  
  if([NetworkReachability reachable] && [settings.userId length] > 0) {
    // 
	  PicasaFetchController *controller = [[PicasaFetchController alloc] init];
	  controller.delegate = self;
	  controller.userId = settings.userId;
	  controller.password = settings.password;
	  [controller queryUserAndAlbums:settings.userId];
  }
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
  NSString *title = NSLocalizedString(@"Error",@"Error");
  NSString *message = NSLocalizedString(@"Error.Auth",@"AUTH ERROR");
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
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


- (void) PicasaFetchWasError:(NSError *)error {
  NSLog(@"connection error");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *title = NSLocalizedString(@"Error",@"Error");
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

