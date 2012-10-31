//
//  ThumbImageView.m
//  PicasaViewer
//
//  Created by nyaago on 2012/10/31.
//
//

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

- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container;
{
  self = [super initWithImage:image];
  if(self) {
    index = [i retain];
    self.userInteractionEnabled = YES;
    containerView = [container retain];
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
  if(delegate != nil)
    [delegate release];
  if(index != nil)
    [index release];
  if(containerView)
    [containerView retain];
  [super dealloc];
}


- (CGRect) frameForThumb:(NSUInteger)n {
  return CGRectMake(0,0,0,0);
}

- (CGPoint) pointForThumb:(NSUInteger)n {
  return CGPointMake(0, 0);
}
@end

