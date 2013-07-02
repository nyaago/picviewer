//
//  ThumbImageView.m
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

#import "ThumbImageView.h"
#import "iPhoneThumbImageView.h"
#import "iPadThumbImageView.h"

@class IPhoneThumbImageView;
@class IPadThumbImageView;
@implementation ThumbImageView

static NSMutableDictionary *thumbViewMap = nil;

@synthesize index;
@synthesize delegate;
@synthesize containerView;


+ (id) viewWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container; {
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    return [[IPadThumbImageView alloc] initWithImage:image withIndex:i withContainer:container];
  }
  else {
    return [[IPhoneThumbImageView alloc] initWithImage:image withIndex:i withContainer:container];
  }
  
}

/*!
 @method findByPoint:
 @discussion Pointよりサムネイルを探す
 */
+ (ThumbImageView *)findByPoint:(CGPoint) point {
  NSArray *views = [thumbViewMap allValues];
  for(int i = 0; i < [views count]; ++i) {
    ThumbImageView *view = (ThumbImageView *)[views objectAtIndex:i];
    CGRect frame = view.frame;
    if(!(point.x >= frame.origin.x && point.x <= frame.origin.x + frame.size.width)) {
      continue;
    }
    if(!(point.y >= frame.origin.y && point.y <= frame.origin.y + frame.size.height)) {
      continue;
    }
    return view;
  }
  return nil;
}

/*!
 @method refresh
 @discussion すべてのサムネイルのリフレッシュ
 */
+ (void) refreshAll:(UIView *)containerView {
  NSArray *views = [thumbViewMap allValues];
  for(int i = 0; i < [views count]; ++i) {
    ThumbImageView *view = (ThumbImageView *)[views objectAtIndex:i];
    if(view.superview) {
      [view performSelectorOnMainThread:@selector(refresh:)
                             withObject:containerView
                          waitUntilDone:YES];
    }
  }
}

/*!
 @method
 @discussion すべてのサムネイルの削除
 */
+ (void) cleanup {
  NSArray *views = [thumbViewMap allValues];
  for(int i = 0; i < [views count]; ++i) {
    ThumbImageView *view = (ThumbImageView *)[views objectAtIndex:i];
    if(view.superview) {
      [view performSelectorOnMainThread:@selector(removeFromSuperview)
                             withObject:nil
                          waitUntilDone:NO];
    }
  }
  [thumbViewMap removeAllObjects];
}

+ (CGPoint) bottomRight {
  NSArray *views = [thumbViewMap allValues];
  CGPoint result = CGPointMake(0.0f, 0.0f);
  for(int i = 0; i < [views count]; ++i) {
    ThumbImageView *view = (ThumbImageView *)[views objectAtIndex:i];
    CGRect frame = view.frame;
    CGPoint point = CGPointMake(frame.origin.x + frame.size.width,
                                frame.origin.y + frame.size.height);
    if(point.x > result.x) {
      result.x = point.x;
    }
    
    if(point.y > result.y) {
      result.y = point.y;
    }
  }
  return result;
 
}

+ (NSUInteger) thumbWidthForContainer:(UIView *)containerView {
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    return [IPadThumbImageView thumbWidthForContainer:containerView];
  }
  else {
    return [IPhoneThumbImageView thumbWidthForContainer:containerView];
  }
}

+ (NSUInteger) thumbHeightForContainer:(UIView *)containerView {
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    return [IPadThumbImageView thumbHeightForContainer:containerView];
  }
  else {
    return [IPhoneThumbImageView thumbHeightForContainer:containerView];
  }
}


- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container
{
  self = [super initWithImage:image];
  if(self) {
    index = [i retain];
    self.userInteractionEnabled = YES;
    containerView = container;
    self.frame = [self frameForThumb:index.integerValue];
  }
  if(thumbViewMap == nil) {
    thumbViewMap = [[NSMutableDictionary alloc] init];
  }
  UIView *oldView = (UIView *)[thumbViewMap objectForKey:i];
  if(oldView != nil) {
    [oldView release];
    oldView = nil;
  }
  [thumbViewMap setObject:self forKey:i];
  return self;
}

- (id) refresh:(UIView *)containerView {
  
  self.containerView = containerView;
  self.frame = [self frameForThumb:index.integerValue];
  return self;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if(delegate) {
    [delegate photoTouchesEnded:self
                        touches:touches
                      withEvent:event];
  }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  //  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  //  [[self nextResponder] touchesMoved:touches withEvent:event];
}

- (void) dealloc {
  if(index != nil)
    [index release];
  [super dealloc];
}


- (CGRect) frameForThumb:(NSUInteger)n {
  return CGRectMake(0,0,0,0);
}

- (CGPoint) pointForThumb:(NSUInteger)n {
  return CGPointMake(0, 0);
}
@end

