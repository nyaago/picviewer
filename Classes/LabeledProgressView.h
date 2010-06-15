//
//  ProgressView.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LabeledProgressView : UIView {
  
  @private
  
	UILabel *messageLabel;
  UIProgressView *progressView;
}

- (void) setMessage:(NSString *)message;

@property (nonatomic, retain) UIProgressView *progressView;


@end
