//
//  AlbumInfoViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/05/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AlbumInfoViewController.h"

@interface  AlbumInfoViewController(Private)

/*!
 @method completedAction:
 @discussion 完了ボタンのアクション、親Viewへ戻る
 */
- (void) completedAction:(id)sender;

@end


@implementation AlbumInfoViewController

@synthesize album;

- (id)initWithAlbumObject:(Album *)albumObject {
	self = [super initWithStyle:UITableViewStyleGrouped];
  if(self) {
    //
    self.album = albumObject;
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

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
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
	UIBarButtonItem *completeButton = [[UIBarButtonItem alloc] 
                    initWithBarButtonSystemItem:UIBarButtonSystemItemDone                    
                    target:self 
                    action:@selector(completedAction:) ];
	self.navigationItem.rightBarButtonItem = completeButton;
  self.navigationController.navigationBarHidden = NO;
  [completeButton release];
}
  
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
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
  [super viewDidUnload];
}

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


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSInteger n = 0;
  switch (section) {
    case 0:
      n = 3;
    default:
      break;
  }
  return n;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
//  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  static NSString *CellIdentifier = @"Cell";
	  

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  NSString *fmt;
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                   reuseIdentifier:CellIdentifier] autorelease];
    switch ([indexPath indexAtPosition:0]) {
      case(0) : //
        switch ([indexPath indexAtPosition:1]) {
          case(0) :
            cell.textLabel.text = self.album.title;
            break;
          case(1) :
            cell.textLabel.text = NSLocalizedString(self.album.access, @"?");
            break;
          case(2) :
            fmt = NSLocalizedString(@"AlbumInfo.PhotosUsed", @"cnt");
            cell.textLabel.text = [NSString stringWithFormat:fmt, 
                                   [self.album.photosUsed intValue] ];
            break;
          default:
        break;
        }
    }
  }
  
  // Set up the cell...
//	[pool drain];
  return cell;
}


- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController 
  // = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


- (void) completedAction:(id)sender {
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}


- (void)dealloc {
  if(album) {
	  [album release];
  }
  [super dealloc];
}


@end

