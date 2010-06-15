//
//  LabeledActivityIndicator.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @class LabeledActivityIndicator
 @discussion Message表示のLabelを含むActivityIndicatorView
 */
@interface LabeledActivityIndicator : UIView {

@private
  
	UILabel *messageLabel;
  UIActivityIndicatorView *indicatorView;
  // Indicator表示中のバックグラウンド処理を実行する対象のObject
  id target;
  // Indicator表示中の処理として送信されるSelector 
  SEL selector;
}

/*!
 @method setMessage:
 @discussion 表示するメッセージを設定
 */
- (void) setMessage:(NSString *)message;

/*!
 @property indicatorView
 */
@property (nonatomic, retain) UIActivityIndicatorView *indicatorView;

/*!
 @method start
 @discussion IndicatorのAnimation表示を開始する
 */
- (void) start;

/*!
 @method stop
 @discussion IndicatorのAnimation表示を停止する
 */
- (void) stop;


/*!
 @method startWithTarget:withSelector:
 @discussion 表示中に実行する処理を指定して、このViewの表示とIndicatorのAnimationを開始する。
 処理が完了すれば、Animationを停止する
 @param target - The object to which to send the message specified by aSelector.
 @param aSelector - The message to send to target
 */
- (void) startWithTarget:(id)target withSelector:(SEL)aSelector withObject:(id)arg;

@end


/*!
 @protocal LabeledActivityIndicator
 @discussion LabeledActivityIndicatorに対するDelegate
 */
@protocol LabeledActivityIndicatorDelegate

/*!
 @method
 @discussion 
 */
- (void) indicatorStoped:(LabeledActivityIndicator *)indicatorView;

@end

