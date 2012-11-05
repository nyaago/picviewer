//
//  IPadThumbImageView.m
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
  NSInteger w = containerView.frame.size.width;
  return (w - kMargin * 2) / 4;
}

- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container
{
  self = [super initWithImage:image withIndex:i withContainer:container];
  self.layer.borderWidth = kBorderWidth;
  self.layer.borderColor = [[UIColor colorWithRed:0.5f green:0.4f blue:0.5f alpha:0.5f]
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
