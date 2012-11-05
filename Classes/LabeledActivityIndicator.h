//
//  LabeledActivityIndicator.h
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

