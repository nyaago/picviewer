//
//  NewUserViewController.m
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

#import "NewUserViewController.h"


@implementation NewUserViewController

@synthesize doneButton, cancelButton;
@synthesize userField;
@synthesize captionLabel, explanationLabel;
@synthesize navigationTitle;
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

- (void)loadView {
  [super loadView];
}


 // Implement viewDidLoad to do additional setup after loading the view, 
 //typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
  navigationTitle.text = NSLocalizedString(@"NewUser.Title", @"Add");
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
}

- (void) cancelAction:(id)sender {
  [[self presentingViewController] dismissModalViewControllerAnimated:YES];
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
