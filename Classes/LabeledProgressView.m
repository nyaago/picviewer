//
//  ProgressView.m
//  PicasaViewer
//
//  Created by nyaago on 10/06/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LabeledProgressView.h"


@implementation LabeledProgressView


@synthesize progressView;

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
    self.backgroundColor = [UIColor grayColor];
    messageLabel.backgroundColor = [UIColor grayColor];
    
  }
  
  return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

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



@end
