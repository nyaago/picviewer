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


@interface PhotoInfoViewController(Private)

/*!
 @method completedAction:
 @discussion 完了ボタンのアクション、親Viewへ戻る
 */
- (void) completedAction:(id)sender;

@end


@implementation PhotoInfoViewController

@synthesize photo;

#pragma mark -
#pragma mark View lifecycle

- (id)initWithPhotoObject:(Photo *)photoObject {
	self = [super initWithStyle:UITableViewStyleGrouped];
  if(self) {
    //
    self.photo = photoObject;
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
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
  NSInteger n = 0;
  switch (section) {
    case 0:
      n = 2;
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
    switch ([indexPath indexAtPosition:0]) {
      case(0) : //
        switch ([indexPath indexAtPosition:1]) {
          case(0) :
            cell.textLabel.text = self.photo.title;
            break;
//          case(1) :
//            cell.textLabel.text = self.photo.descript;
//            break;
          case(1) :
            cell.textLabel.text = [NSString stringWithFormat:@"%@ = %@",
                                   NSLocalizedString(@"Location", @"Location"),
                                   self.photo.location];
            break;
          /*  
          case(2) :
            {
            NSString *w = NSLocalizedString(@"Width", @"Width");
            NSString *h = NSLocalizedString(@"Height", @"Height");
            cell.textLabel.text = [NSString stringWithFormat:@"%@:%@ = %d:%d", 
                                   w, h,
                                   [self.photo.width intValue], 
                                   [self.photo.height intValue] ];
            }
            break;
           */
          default:
            break;
        }
    }
  }
  
  // Set up the cell...
  //	[pool drain];
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
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
  [super dealloc];
}

#pragma mark -


#pragma mark Action
- (void) completedAction:(id)sender {
  [[self parentViewController] dismissModalViewControllerAnimated:YES];
}

@end

