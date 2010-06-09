#import "PageControlViewController.h"

@implementation PageScrollView

//@synthesize delegate;
@synthesize prevPage,curPage, nextPage;
@synthesize curPageNumber;

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self != nil) {
    self.delegate = nil;
    self.pagingEnabled = YES;
    self.userInteractionEnabled = YES;
    self.scrollEnabled = YES;
    self.delegate = self;
    self.multipleTouchEnabled = NO;
    self.directionalLockEnabled = YES;
    self.bounces = NO;
    self.showsHorizontalScrollIndicator = NO;  
    self.showsVerticalScrollIndicator = NO;  
    self.backgroundColor = [UIColor blackColor];
  }
  return self;
}

- (void)setPageCount:(NSUInteger)n {
  pageCount = n;
  CGRect pageRegion = CGRectMake(self.frame.origin.x, self.frame.origin.y, 
                                 self.frame.size.width, self.frame.size.height);
  self.contentOffset = CGPointMake(0.0, 0.0);
  if (pageCount < 3) {
    self.contentSize = CGSizeMake(pageRegion.size.width * pageCount, 
                                  pageRegion.size.height);
  } else {
    self.contentSize = CGSizeMake(pageRegion.size.width * 3, 
                                  pageRegion.size.height);
    self.showsHorizontalScrollIndicator = NO;
  }
}

- (CGPoint) pointForCurPage {
  NSUInteger left = curPageNumber == 0 ? 0 : self.frame.size.width;
  return CGPointMake(left, 0.0f);
}

- (void)setCurPage:(UIViewController *)newView withPageNumber:(NSUInteger)n {
  curPageNumber = n;
  NSUInteger left = curPageNumber == 0 ? 0 : self.frame.size.width;
  left += 2.0f;
  CGRect pageRegion = CGRectMake(left, 0.0f, 
                                 self.frame.size.width, 
                                 self.frame.size.height - 4.0f);
  newView.view.frame = pageRegion;
  if(curPage) {
    NSLog(@"curPage retain %d,and release", [curPage retainCount]);
    [curPage release];
    curPage = nil;
  }
  curPage = newView;
  [curPage retain];
  [self addSubview:newView.view];
  [newView.view setNeedsDisplay];
  self.contentOffset = CGPointMake(left, 0.0f);
}

- (void)setNextPage:(UIViewController *)newView {
  NSUInteger left = 
  	curPageNumber == 0 ? self.frame.size.width : self.frame.size.width * 2 ;
  left += 2.0f;
  CGRect pageRegion = CGRectMake(left, 0.0f, 
                                 self.frame.size.width - 4.0f, 
                                 self.frame.size.height);
  if(nextPage) {
    [nextPage release];
    nextPage = nil;
  }
  nextPage = newView;
  [nextPage retain];
  nextPage.view.frame = pageRegion;
  [self addSubview:nextPage.view];
}

- (void)setPrevPage:(UIViewController *)newView {
  NSUInteger left =  0 + 2.0f;
  CGRect pageRegion = CGRectMake(left, 0.0f, 
                                 self.frame.size.width - 4.0f, 
                                 self.frame.size.height);
  if(prevPage) {
    [prevPage release];
    prevPage = nil;
  }
  prevPage = newView;
  [prevPage retain];
  prevPage.view.frame = pageRegion;
  [self addSubview:prevPage.view];
}

/*
- (void)toCurPage {
  // scrollで移動して..
  NSLog(@"to cur page start");
  NSUInteger left = curPageNumber == 0 ? 0 : self.frame.size.width * 1;
  [self setContentOffset:CGPointMake(left, 0.0f) animated:YES];
  NSLog(@"to cur page end");
}
 */

- (UIViewController *)toNextPage {
  // page入れ替え
  UIViewController *tmp; // 交換用
  UIViewController *popedView;
  tmp = curPage;
  curPage = nextPage;
  curPage.view.hidden = NO;
  //[prevPage removeFromSuperview];
  popedView = prevPage;
  //  [prevPage release];
  prevPage = nil;
  prevPage = tmp;
  nextPage = nil;
  curPageNumber += 1;
  // 再表示
  //  [self layoutViews];
  NSLog(@"toNextView poppedView retain count = %d", [popedView retainCount]);
  [popedView.view removeFromSuperview];
  [popedView release];
  return popedView;
}

- (UIViewController *)toPrevPage {
  // scrollで移動して..
  //  NSUInteger left = 0;
  //  [scrollView setContentOffset:CGPointMake(left, 0.0f) animated:YES];
  // page入れ替え
  UIViewController *tmp;
  UIViewController *popedView;
  tmp = curPage;
  curPage = prevPage;
  curPage.view.hidden = NO;
  //[nextPage removeFromSuperview];
  popedView = nextPage;
  //  [nextPage release];
  nextPage = nil;
  nextPage = tmp;
  prevPage = nil;
  curPageNumber -= 1;
  // 再表示
  //  [self layoutViews];
  NSLog(@"toPrevView poppedView retain count = %d", [popedView retainCount]);
  [popedView.view removeFromSuperview];
  [popedView release];
  return popedView;
}


- (void) layoutViews {
  // prev
  NSUInteger left = 0;
  if(prevPage) {
    CGRect pageRegion = CGRectMake(left, self.frame.origin.y, 
                                   self.frame.size.width, 
                                   self.frame.size.height);
    prevPage.view.frame = pageRegion;
  }
  
  // cur
  if(curPageNumber > 0) {
    left += self.frame.size.width;
  }
  if(curPage) {
    CGRect pageRegion = CGRectMake(left, self.frame.origin.y, 
                                   self.frame.size.width, 
                                   self.frame.size.height);
    curPage.view.frame = pageRegion;
  }
  // next
  left += self.frame.size.width;
  if(nextPage) {
    CGRect pageRegion = CGRectMake(left, self.frame.origin.y, 
                                   self.frame.size.width, 
                                   self.frame.size.height);
    nextPage.view.frame = pageRegion;
  }
	
  //
  left = curPageNumber == 0 ? 0 : self.frame.size.width * 1;
  //  left = 640;
  //  left = 320;
  [self setContentOffset:CGPointMake(left, 0.0f) animated:NO];
  if(curPageNumber > 0) {
    left += self.frame.size.width;
  }
  
  CGRect pageRegion = CGRectMake(0, self.frame.origin.y, 
                                 self.frame.size.width, 
                                 self.frame.size.height);
  if(curPageNumber == 0 || nextPage == nil) {
    self.contentSize = CGSizeMake(pageRegion.size.width * 2, 
                                  pageRegion.size.height);
  }
  else {
    self.contentSize = CGSizeMake(pageRegion.size.width * 3, 
                                  pageRegion.size.height);
  }
  
  
}

- (void)removeCurPage {
  if(curPage){
    [curPage.view removeFromSuperview];
    [curPage release];
    curPage = nil;
  }
}

- (void)removeNextPage {
  if(nextPage) {
    [nextPage.view removeFromSuperview];
    [nextPage release];
    nextPage = nil;
  }
}

- (void)removePrevPage {
  if(prevPage) {
    [prevPage.view removeFromSuperview];
    [prevPage release];
    prevPage = nil;
  }
}

/*
 - (void)setDelegate:(id<PageScrollViewDelegate, UIScrollViewDelegate>)newDelegate{
 delegate = newDelegate;
 [delegate retain];
 scrollView.delegate = newDelegate;
 }
 */

- (void)dealloc {
  NSLog(@"PageScrollView dealloc");
  /*
   if(prevPage) {
   NSLog(@"prevPage retain count = %d", [prevPage retainCount]);
   }
   if(curPage) {
   NSLog(@"curPage retain count = %d", [curPage retainCount]);
   }
   if(nextPage)  {
   NSLog(@"nextPage retain count = %d", [nextPage retainCount]);
   }
   */
  [self removeCurPage];
  [self removePrevPage];
  [self removeNextPage];
  [super dealloc];
}

@end
