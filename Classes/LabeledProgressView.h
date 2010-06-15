//
//  ProgressView.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @class LabeledProgressView
 @discussion Message表示のLabelを含むProgressView
 */
@interface LabeledProgressView : UIView {
  
  @private
  
	UILabel *messageLabel;
  UIProgressView *progressView;
}

/*!
 @method setMessage:
 @discussion 表示するメッセージテキストを設定
 */
- (void) setMessage:(NSString *)message;

/*!
 @property progressView
 @discussion 
 */
@property (nonatomic, retain) UIProgressView *progressView;

/*!
 @property progress
 @discussion 現在の進行値
 */
@property (nonatomic, assign) float progress;


/*!
 @method setProgress:
 @discussion 現在の進行値を設定
 */
- (void) setProgress:(float)progress;


/*!
 @method progress
 @discussion 現在の進行値を返す
 */
- (float) progress;


@end
