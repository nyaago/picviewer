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

- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container;
{
  self = [super initWithImage:image];
  if(self) {
    index = [i retain];
    self.userInteractionEnabled = YES;
    containerView = [container retain];
    self.frame = [self frameForThumb:index.integerValue];
  }
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

