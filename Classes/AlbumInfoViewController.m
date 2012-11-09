//
//  AlbumInfoViewController.m
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

#pragma mark View lifecycle

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

#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
  if(album) {
	  [album release];
  }
  [super dealloc];
}

#pragma mark -

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
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
- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
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


- (void) completedAction:(id)sender {
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}


@end

