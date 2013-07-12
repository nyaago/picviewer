//
//  ProgressView.m
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

#import <QuartzCore/QuartzCore.h>
#import "LabeledProgressView.h"


@implementation LabeledProgressView


@synthesize progressView;
@synthesize progress;

- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    // Initialization code
    CGRect rect = CGRectMake(25.0f,
                              80.0f,
                              frame.size.width  - 50.0f, 
                              30.0f);
		progressView = [[UIProgressView alloc] initWithFrame:rect];
    [self addSubview:progressView];
    rect = CGRectMake(25.0f,  
                       20.0f,
                       frame.size.width - 50.0f, 
                       50.0f);
    messageLabel = [[UILabel alloc] initWithFrame:rect];
    
    [self addSubview:messageLabel];
    self.backgroundColor = [UIColor blackColor];
    messageLabel.backgroundColor =  [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
    messageLabel.textColor = [UIColor whiteColor];
    
    self.backgroundColor = [UIColor grayColor];
    
    self.layer.cornerRadius = 10;
    self.clipsToBounds = YES;
    CGColorRef borderColor = [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f] CGColor];
    self.layer.borderColor = borderColor;
    self.layer.borderWidth = 2.0f;

  }
  
  return self;
}


- (void)dealloc {
  if(messageLabel)
    [messageLabel release];
  if(progressView)
    [progressView release];
  [super dealloc];
}

- (void) setMessage:(NSString *)message {
  messageLabel.text = message;
}

- (void) setProgress:(float)v {
  progressView.progress = v;
}


- (float) progress {
  return progressView.progress;
}

@end
