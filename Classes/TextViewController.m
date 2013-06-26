//
//  TextViewController.m
//  PicasaViewer
//
//  Created by nyaago on 2013/06/25.
//
//

#import "TextViewController.h"

@interface TextViewController(Private)

- (void) backAction:(id)sender;

@end

@implementation TextViewController

@synthesize textView;
@synthesize delegate;
@synthesize isMustiLine;
@synthesize maxLength;
@synthesize tag;
@synthesize text;
@synthesize keybordType;
@synthesize backButton;

- (void) viewDidLoad {
  [super viewDidLoad];
  
  textView = [[UITextView alloc] initWithFrame:self.view.bounds];
  textView.font = [UIFont systemFontOfSize:16.0f];
  [self.view addSubview:textView];
  
  self.navigationItem.leftBarButtonItem = self.backButton;
  self.navigationItem.hidesBackButton = YES;
}

- (void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.textView setText:self.text ? self.text : @""];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark actions

- (void) backAction:(id)sender {
  
  [self.navigationController popViewControllerAnimated:YES];
  
  if(delegate) {
    [delegate textViewControler:self input:self.textView.text];
  }

}


#pragma mark UI

- (UIBarButtonItem *) backButton {
  if(!backButton) {
    backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                               target:self
                                                               action:@selector(backAction:)];
  }
  return  backButton;
}


#pragma mark UITextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView {
}

- (BOOL)textView:(UITextView *)curTextView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)string {
	NSMutableString *newText = [curTextView.text mutableCopy];
  
  if(self.isMustiLine == NO) {
    
    if ([string isEqualToString:@"\n"]) {
      return NO;
    }
  }
  
  if(maxLength > 0) {
    [newText replaceCharactersInRange:range withString:string];
    return [newText length] <= maxLength;
  }
  return YES;
}


@end
