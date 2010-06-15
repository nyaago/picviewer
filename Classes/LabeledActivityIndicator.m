//
//  LabeledActivityIndicator.m
//  PicasaViewer
//
//  Created by nyaago on 10/06/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LabeledActivityIndicator.h"

@interface LabeledActivityIndicator(Private)

/*!
 @method runTaskWithObject:
 @discussion selector変数で指定されているselectorをtarget変数に指定されている
 オブジェクトに送信.処理完了後indicatorの停止とDelegateメソッドの起動を行う.
 */
- (void)runTaskWithObject:(id)arg;

@end


@implementation LabeledActivityIndicator

@synthesize indicatorView;

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    // Initialization code
    CGRect rect = CGRectMake((frame.size.width - 50.0f) / 2,  
                             50.0f,
                             50.0f, 
                             50.0f);
		indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:rect];
    [self addSubview:indicatorView];
    rect = CGRectMake(25.0f,  
                      20.0f,
                      frame.size.width - 50.0f, 
                      30.0f);
    messageLabel = [[UILabel alloc] initWithFrame:rect];
    [self addSubview:messageLabel];
    self.backgroundColor = [UIColor grayColor];
    messageLabel.backgroundColor = [UIColor grayColor];
    
  }
  return self;
}

- (void) startWithTarget:(id)aTarget withSelector:(SEL)aSelector 
              withObject:(id)arg {
  [indicatorView startAnimating];
  selector = aSelector;
  if(target != aTarget) {
    if(target)
      [target release];
	  target = [aTarget retain];
  }
  [NSThread detachNewThreadSelector:@selector(runTaskWithObject:) 
                           toTarget:self 
                         withObject:arg];
}

- (void) start {
  [indicatorView startAnimating];
}

- (void) stop {
  [indicatorView stopAnimating];
}

- (void)runTaskWithObject:(id)arg {
  [target performSelector:selector withObject:arg];
  [self performSelectorOnMainThread:@selector(stop) 
                         withObject:nil
                      waitUntilDone:YES];
  if([target respondsToSelector:@selector(indicatorStoped:)] ) {
    [target performSelector:@selector(indicatorStoped:) withObject:self];
  }
}

- (void)dealloc {
  if(messageLabel)
    [messageLabel release];
  if(indicatorView)
    [indicatorView release];
  if(target)
    [target release];
  [super dealloc];
}

- (void) setMessage:(NSString *)message {
  messageLabel.text = message;
}


@end
