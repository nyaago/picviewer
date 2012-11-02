//
//  IPadThumbImageView.m
//  PicasaViewer
//
//  Created by nyaago on 2012/10/31.
//
//

#import <QuartzCore/QuartzCore.h>
#import "IPadThumbImageView.h"

@implementation IPadThumbImageView

#define kBorderWidth 3.0f
#define kPadding 5.0f
#define kMargin 6.0f


+ (NSUInteger) thumbWidthForContainer:(UIView *)containerView {
  NSInteger w = containerView.frame.size.width;
  return (w - kMargin * 2) / 4;
  
}

+ (NSUInteger) thumbHeightForContainer:(UIView *)containerView {
  NSInteger w = containerView.frame.size.height;
  return (w - kMargin * 2) / 4;
}

- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container
{
  self = [super initWithImage:image withIndex:i withContainer:container];
  self.layer.borderWidth = kBorderWidth;
  self.layer.borderColor = [[UIColor colorWithRed:0.1f green:0.0f blue:0.3f alpha:0.5f]
                            CGColor];
  return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (CGPoint) pointForThumb:(NSUInteger)n {
   NSLog(@"width = %f, height = %f", self.containerView.bounds.size.width,
          self.containerView.bounds.size.height);
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = kPadding;
  NSUInteger cols = self.containerView.bounds.size.width / w;
  NSUInteger row = n / cols;	// base - 0
  NSUInteger col = n % cols;	// base - 0
  return CGPointMake(col * h + padding, row * w + padding + kPadding);
}

- (CGRect) frameForThumb:(NSUInteger)n {
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 4.0f;
  CGPoint point = [self pointForThumb:n];
  return CGRectMake(point.x, point.y, w - padding * 2, h - padding *2);
}

- (NSUInteger) thumbWidth {
  return [[self class] thumbWidthForContainer:self.containerView];
}

- (NSUInteger) thumbHeight {
  return [[self class] thumbHeightForContainer:self.containerView];
}

@end
