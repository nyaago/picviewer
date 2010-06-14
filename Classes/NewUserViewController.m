//
//  NewUserViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NewUserViewController.h"


@implementation NewUserViewController

@synthesize doneButton, cancelButton;
@synthesize userField;
@synthesize captionLabel, explanationLabel;
@synthesize delegate;

/*
 // The designated initializer.  Override if you create the controller programmatically 
 //and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

 // Implement viewDidLoad to do additional setup after loading the view, 
 //typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
  captionLabel.text = NSLocalizedString(@"NewUser.Account", @"Account");
  explanationLabel.text = NSLocalizedString(@"NewUser.Explanation", @"");
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

- (void)viewDidUnload {
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

#pragma mark action

- (void) doneAction:(id)sender {
  if(delegate) {
    if([delegate doneWithNewUser:userField.text] == NO)
      return;
  }
  //  [self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void) cancelAction:(id)sender {
  [self.parentViewController dismissModalViewControllerAnimated:YES];
}


#pragma mark -


- (void)dealloc {
  [doneButton release];
  [cancelButton release];
  if(delegate)
    [delegate release];
  [super dealloc];
}


@end
