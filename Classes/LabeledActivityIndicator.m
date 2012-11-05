//
//  LabeledActivityIndicator.m
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
