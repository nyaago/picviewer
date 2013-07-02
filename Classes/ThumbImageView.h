//
//  ThumbImageView.h
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

#import <Foundation/Foundation.h>

@class ThumbImageView;

@protocol ThumbImageViewDelegate

/*!
 @method photoTouchesEnded:withEvnet:
 */
- (void)photoTouchesEnded:(ThumbImageView *)imageView
                  touches:(NSSet *)touches
                withEvent:(UIEvent *)event;

@end

@interface ThumbImageView : UIImageView
{
  @private
  
  NSObject <ThumbImageViewDelegate> *delegate;
  UIView *containerView;
  NSNumber *index;
  // key => Index, value => ThumbImageView
  
}

+ (id) viewWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container;

/*!
 @method findByPoint:
 @discussion Pointよりサムネイルを探す
 */
+ (ThumbImageView *)findByPoint:(CGPoint) point;


/*!
 @method
 @discussion すべてのサムネイルの削除
 */
+ (void) cleanup;

/*!
 @method
 @discussion すべてのサムネイルの右下の座標
 */
+ (CGPoint) bottomRight ;

/*!
 @method
 @discussion すべてのサムネイルの右下の座標
 */
+ (void) refreshAll:(UIView *)containerView;


/*!
 @method thumbWidthForContainer:
 @discussion サムネイルの幅を得る
 @param containerView コンテナーとなる親View
 */
+ (NSUInteger) thumbWidthForContainer:(UIView *)containerView;

/*!
 @method thumbHeightForContainer:
 @discussion サムネイルの高さを得る
 @param containerView コンテナーとなる親View
 */
+ (NSUInteger) thumbHeightForContainer:(UIView *)containerView;

/*!
 @method
 @discussion image を指定しての生成
 */
- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container;

/*!
 @method refresh
 @discussion
 */
- (id) refresh:(UIView *)containerView;

/*!
 @method setDelegate
 @discussion delegateの設定
 */
- (void) setDelegate:(NSObject <ThumbImageViewDelegate> *) delegate;

/*!
 @method delegate
 */
- (NSObject <ThumbImageViewDelegate> *)delegate;

/*!
 @method frameForThumb
 @discussion viewのframeを返す
 @param n index - 0起点
 */
- (CGRect) frameForThumb:(NSUInteger)n;

- (CGPoint) pointForThumb:(NSUInteger)n;

@property (readonly, nonatomic) NSNumber *index;

@property (assign, nonatomic) NSObject <ThumbImageViewDelegate> *delegate;

@property (assign, nonatomic) UIView *containerView;
@end

