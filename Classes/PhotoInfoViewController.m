//
//  PhotoInfoViewController.m
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

#import "PhotoInfoViewController.h"
#import "SettingsManager.h"

#define kTagAlertDelete 1

@interface PhotoInfoViewController(Private)

/*!
 @method completedAction:
 @discussion 完了ボタンのアクション、親Viewへ戻る
 */
- (void) completedAction:(id)sender;


- (void) confirmDelete;

- (void) doDelete;


- (NSInteger) lineCountOfString:(NSString *)s;


@end


@implementation PhotoInfoViewController

@synthesize photo;
@synthesize picasaController;
@synthesize canUpdate;
@synthesize managedObjectContext;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithPhotoObject:(Photo *)photoObject canUpdate:(BOOL)fCanUpdate {
	self = [super initWithStyle:UITableViewStyleGrouped];
  if(self) {
    //
    self.photo = photoObject;
    self.canUpdate = fCanUpdate;
    //
    UIBarButtonItem *completeButton = [[UIBarButtonItem alloc] 
                                       initWithTitle:
                                       NSLocalizedString(@"Completed", @"Completed")
                                       style:UIBarButtonItemStyleBordered 
                                       target:self
                                       action:@selector(completedAction:)];
    self.navigationItem.rightBarButtonItem = completeButton;
    [completeButton release];
  }
  return self;
}


/*!
 @method viewDidLad
 @discussion View Load時の通知.navigationBarの設定、設定情報管理Objectの生成
 */
- (void)viewDidLoad {
  [super viewDidLoad];
	UIBarButtonItem *completeButton = [[UIBarButtonItem alloc] 
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemDone                    
                                     target:self 
                                     action:@selector(completedAction:) ];
	self.navigationItem.rightBarButtonItem = completeButton;
  self.navigationController.navigationBarHidden = NO;
  [completeButton release];
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
  if(self.canUpdate) {
    return 2;
  }
  else {
    return 1;
  }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
  NSInteger n = 0;
  switch (section) {
    case 0:
      n = 2;
      break;
    case 1:
      n = 1;
      break;
    default:
      break;
  }
  return n;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
  static NSString *CellIdentifier = @"Cell";
  
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
  }
  switch ([indexPath indexAtPosition:0]) {
    case(0) : //
      switch ([indexPath indexAtPosition:1]) {
        case(0) :
          cell.textLabel.text = self.photo.descript;
          if(self.canUpdate) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          }
          break;
        case(1) :
          cell.textLabel.text = [NSString stringWithFormat:@"%@ = %@",
                                 NSLocalizedString(@"Location", @"Location"),
                                 self.photo.location ? self.photo.location : @""];
          break;
        default:
          break;
      }
      break;
    case (1) :
      switch ([indexPath indexAtPosition:1]) {
        case(0) :
          cell.textLabel.text = NSLocalizedString(@"PhotoInfo.DeletePhoto", @"Delete Photo");
          cell.textLabel.textColor = [UIColor redColor];
          cell.selectionStyle = UITableViewCellSelectionStyleBlue;
          break;
        default:
          break;
      }
      break;
  }
  
  // Set up the cell...
  //	[pool drain];
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
  switch ([indexPath indexAtPosition:0]) {
    case(0) :
      switch ([indexPath indexAtPosition:1]) {
        case (0):
          // descript
          if([self canUpdate]) {
            TextViewController *textViewController = [[TextViewController alloc] init];
            textViewController.delegate = self;
            textViewController.text = photo.descript;
            [self.navigationController pushViewController:textViewController
                                                 animated:YES];
          }
          break;
        default:
          break;
      }
      break;
    case (1) :
      switch ([indexPath indexAtPosition:1]) {
        case (0):
          // 削除
          [self confirmDelete];
          break;
          
        default:
          break;
      }
      break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  CGFloat height = 45.0f;
  CGFloat h = 0.0f;
  switch ([indexPath indexAtPosition:0]) {
    case 0:
      switch ([indexPath indexAtPosition:1]) {
        case 0:
          h = [self lineCountOfString:photo.descript] * 25.0f;
          height = h  > height ? h : height;
          break;
        default:
          break;
      }
      break;
      
    default:
      break;
  }
  return height;
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}


- (void)dealloc {
  if(photo) {
		[photo release];
  }
  if(picasaController) {
    [picasaController release];
  }
  if(modelController) {
    [modelController release];
  }
  if(managedObjectContext) {
    [managedObjectContext release];
  }
  [super dealloc];
}

#pragma mark -

#pragma mark action when cell selected

- (void) confirmDelete {
  
  UIAlertView *av = [[UIAlertView alloc]
                     initWithTitle:NSLocalizedString(@"Notice", @"Notice")
                     message:NSLocalizedString(@"Notice.DeletePhoto", @"confirm deleting.")
                     delegate:self
                     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                     otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
  av.tag = kTagAlertDelete;
  
  [av show];
}


#pragma mark Action
- (void) completedAction:(id)sender {
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  NSLog(@"alert view - selected index = %d", buttonIndex);
  if(alertView.tag == kTagAlertDelete) {
    // 削除確認
    if(buttonIndex) {
      Album *album = (Album *)photo.album;
      User *user = (User *)album.user;
      [self.picasaController deletePhoto:photo.photoId album:album.albumId user:user.userId];
    }
  }
}


#pragma mark PicasaFetchControllerDelegate


- (void)deletedPhoto:(GDataEntryPhoto *)entry
                         error:(NSError *)error {
  if(error) {
    NSLog(@"%@", error.description);
  }
  else {
    [[self photoModelController] removePhoto:photo];
    PicasaViewerAppDelegate *appDelegate
    = (PicasaViewerAppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *preseingViewController = [self presentingViewController];
    [[self presentingViewController] dismissViewControllerAnimated:NO completion:^{
      appDelegate.photoListViewController.needToLoad = YES;
      if(appDelegate.navigationController.splitViewController) {
        // ipad
        [[preseingViewController presentingViewController] dismissViewControllerAnimated:YES
                                                                              completion:^{}];
        [appDelegate.photoListViewController refreshPhotos:NO];
      }
      else {
        // iphone
        [appDelegate.navigationController popToViewController:appDelegate.photoListViewController
                                                     animated:NO];
      }
    }];
  }
}

- (void)updatedPhoto:(GDataEntryPhoto *)entry
               error:(NSError *)error {
  if(error) {
    NSLog(@"%@", error.description);
  }
  else {
    self.photo.changedAtLocal = [NSNumber numberWithBool:NO];

    NSLog(@"updated");
  }
}


- (void) popToRoot {
  PicasaViewerAppDelegate *appDelegate
  = (PicasaViewerAppDelegate *)[[UIApplication sharedApplication] delegate];

  [appDelegate.detailNavigationController popToRootViewControllerAnimated:YES];
}

#pragma mark property

- (PicasaFetchController *) picasaController {
  if(picasaController == nil) {
    picasaController = [[PicasaFetchController alloc] init];
    SettingsManager *settings = [[SettingsManager alloc] init];
    picasaController.userId = settings.userId;
    picasaController.password = settings.password;
    picasaController.delegate = self;
    [settings release];
  }
  return picasaController;
}


- (PhotoModelController *) photoModelController {
  if(modelController == nil) {
    modelController = [[PhotoModelController alloc]
                       initWithContext:self.managedObjectContext];
  }
  if(modelController.managedObjectContext == nil) {
    modelController.managedObjectContext = self.managedObjectContext;
  }
  return modelController;
}

#pragma mark TextViewControllerDelegate

- (void) textViewControler:(TextViewController *)controller input:(NSString *)s {
  if( [s isEqualToString:self.photo.descript] ) {
    return;
  }
  self.photo.descript = s;
  self.photo.changedAtLocal = [NSNumber numberWithBool:YES];
  [[self photoModelController] save];
  
  Album *album = (Album *)photo.album;
  User *user = (User *)album.user;
  
  [self.picasaController updatePhoto:photo album:album.albumId user:user.userId];

  [controller release];
  [self.tableView reloadData];
}


#pragma mark Private


- (NSInteger) lineCountOfString:(NSString *)s {
  if(s == nil) {
    return 1;
  }
  NSMutableArray  *lines = [NSMutableArray array];
  [s enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
    [lines addObject:line];
  }];
  return lines.count;
  
}


@end

