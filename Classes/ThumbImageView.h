//
//  ThumbImageView.h
//  PicasaViewer
//
//  Created by nyaago on 2012/10/31.
//
//

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
+ (void) refreshAll;


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
- (id) refresh;

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

@property (retain, nonatomic) NSObject <ThumbImageViewDelegate> *delegate;

@property (readonly, nonatomic) UIView *containerView;
@end

