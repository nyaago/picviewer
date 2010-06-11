//
//  PhotoInfoViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/06/09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


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
      n = 3;
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
            cell.textLabel.text = self.photo.location;
            break;
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
          default:
            break;
        }
    }
  }
  
  // Set up the cell...
  //	[pool drain];
  return cell;
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
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

