//
//  IPadThumbImageView.m
//  PicasaViewer
//
//  Created by nyaago on 2012/10/31.
//
//

#import "IPadThumbImageView.h"

@implementation IPadThumbImageView

- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container
{
  self = [super initWithImage:image withIndex:i withContainer:container];
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
  //  NSLog(@"width = %f, height = %f", self.scrollView.bounds.size.width,
  //        self.scrollView.bounds.size.height);
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  NSUInteger cols = self.containerView.bounds.size.width / w;
  NSUInteger row = n / cols;	// base - 0
  NSUInteger col = n % cols;	// base - 0
  return CGPointMake(col * h + padding, row * w + padding);
}

- (CGRect) frameForThumb:(NSUInteger)n {
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  CGPoint point = [self pointForThumb:n];
  return CGRectMake(point.x, point.y, w - padding * 2, h - padding *2);
}

- (NSUInteger) thumbWidth {
  NSInteger w = self.containerView.frame.size.width;
  if(w > 640) {
    return w / 6;
  }
  else {
    return w / 4;
  }
}

- (NSUInteger) thumbHeight {
  NSInteger w = self.containerView.frame.size.width;
  if(w > 640) {
    return w / 6;
  }
  else {
    return w / 4;
  }
}

@end
