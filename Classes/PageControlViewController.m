#import "PageControlViewController.h"

#import <UIKit/UIKit.h>

@interface PageControlViewController(Private)

/*!
 @method resetScrollOffsetAndInset:
 @discussion scrollViewのcontentのoffsetとInsetを初期状態に戻す。
 (toolbarの表示/非表示を切り替えるとずれるため,この処理を行う)
 */
- (void)resetScrollOffsetAndInset:(id)arg;

/*!
 @method setToolbarStatus
 @discussion Toolbarの状態の設定
 */
- (void)setToolbarStatus;

@end

/*!
 @class PageScrollView
 @discussion ページめくりのできるScrollView
 */

@implementation PageControlViewController

@synthesize source;
//@synthesize scrollView;

#pragma mark View lifecycle

/*!
 @method loadView
 @discussion ViewLoad, 
 */
- (void)loadView {
  NSLog(@"PageControllerViewController load ratain count = %d",
        [self retainCount]);
  [ super loadView ];
  // StatusBarの高さを取得しておく
  statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
  
  // Scroll View 生成して階層に追加
  CGRect scrollViewBounds = [[UIScreen mainScreen] bounds];
  PageScrollView *scrollView = [ [ PageScrollView alloc ] 
                                initWithFrame:scrollViewBounds];
  scrollView.delegate = self;
  self.view = scrollView;
}

// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
// Viewロードの通知 - デバイス回転管理の開始、StatusBar, NavigationBarの設定
- (void)viewDidLoad {
  NSLog(@"PageControllerViewController view Did Load ratain count = %d", 
        [self retainCount]);
  orientation = UIDeviceOrientationPortrait;
}

/*!
 @method viewDidUnload
 @discussion view Unload時の通知
 */
- (void)viewDidUnload {
  [super viewDidUnload];
  NSLog(@"PageControllerViewController view Did unload ratain count = %d", 
        [self retainCount]);
  if(source) {
    NSLog(@"source retain count %d", [source retainCount]);
  }
}

/*!
 @method viewWillAppear:
 @discussion viewが表示される前の通知、toolbarの表示とViewの全画面表示の設定
 */
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
	self.toolbarItems = [self toolbarButtons];
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = YES;
  self.navigationController.toolbarHidden = YES; 
  // 全画面表示
  self.wantsFullScreenLayout = YES;
}

/*!
 @method viewDidDisappear:
 @discussion viewが表示非表示になったときの通知.各ページのViewの削除
 */
- (void)viewDidDisappear:(BOOL)animated {
  NSLog(@"PageControllerViewController view Did Disappear ratain count = %d",
        [self retainCount]);
  [super viewDidDisappear:animated];
  if(source) {
    NSLog(@"source retain count %d", [source retainCount]);
  }
  NSLog(@"scrollView retain count %d", [self.view retainCount]);
  PageScrollView *scrollView = (PageScrollView *)self.view;
  [scrollView removeCurPage];
  [scrollView removeNextPage];
  [scrollView removePrevPage];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"PageControllerViewController view Did Appear ratain count = %d", 
        [self retainCount]);
  NSLog(@"scrollView retain count %d", [self.view retainCount]);
  
  //  [super viewDidLoad];
  // デバイス回転の管理
  if(!deviceRotation) {
    deviceRotation = [[DeviceRotation alloc] initWithDelegate:self];
  }
  //
  NSLog(@"deviceRotation retain count %d", [deviceRotation retainCount]);
  if(source) {
    NSLog(@"source retain count %d", [source retainCount]);
  }
  
  // Navigation Bar, Status Bar, ToolBarのスタイル(透明、黒）
  self.navigationController.navigationBar.barStyle 
  = UIBarStyleBlackTranslucent;
  [UIApplication sharedApplication].statusBarStyle 
  = UIStatusBarStyleBlackTranslucent;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = YES;
  // Navigation Bar, Status Bar, ToolBarを非表示に
  [UIApplication sharedApplication].statusBarHidden = NO;
  self.navigationController.navigationBar.hidden = NO;
  self.navigationController.toolbarHidden = NO;
  
  // UIViewControllerWrapperView(NavigationViewの親)-
  // FullScreenに(StatusBarの高さ分上へ)
  //  UIView *v = self.view.superview;
  //  CGRect rect = [[UIScreen mainScreen] bounds];
  //  v.frame = rect;
  
  //
  PageScrollView *scrollView = (PageScrollView *)self.view;
  if(source) {
    NSUInteger count = [source pageCount];
    [scrollView setPageCount:count];
    // 現在ページ追加
    if(scrollView.curPageNumber < count) {
      UIViewController<ScrolledPageViewDelegate> *controller 
      = [source pageAt:scrollView.curPageNumber];
      [controller setPageController:self];
      [scrollView setCurPage:controller withPageNumber:scrollView.curPageNumber];
      [controller pageDidAddWithPageScrollViewController:self 
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller release];
      
      //  [controller viewDidAppear:YES];
    }
    // 次ページ
    if(scrollView.curPageNumber + 1 < count) {
      UIViewController<ScrolledPageViewDelegate> *controller 
      = [source pageAt:scrollView.curPageNumber + 1];
      [scrollView setNextPage:controller];
      [controller pageDidAddWithPageScrollViewController:self
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller setPageController:self];
      controller.view.hidden = YES;
      [controller release];
    }
    // 前ページ
    if(scrollView.curPageNumber > 0) {
      UIViewController<ScrolledPageViewDelegate> *controller 
      = [source pageAt:scrollView.curPageNumber - 1];
      [scrollView setPrevPage:controller];
      [controller pageDidAddWithPageScrollViewController:self
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller setPageController:self];
      controller.view.hidden = YES;
      [controller release];
    }
  }
  // scrollview内のviewのLayout
  [scrollView layoutViews];
  // Toolbarのボタンの状態設定
  [self setToolbarStatus];
  //  [scrollView toCurPage];
}

/*!
 @method viewWillDisappear: 
 */
- (void)viewWillDisappear:(BOOL)animated {
  NSLog(@"PageControlView will disappear");
  [deviceRotation release];
  deviceRotation = nil;
  if(source) {
    NSLog(@"source retain count %d", [source retainCount]);
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  //  [UIApplication sharedApplication].statusBarHidden = YES;
  //  self.navigationController.navigationBar.hidden = YES;
  
  return YES;
}

/*
 touch終了
 */
/*
 - (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
 NSLog(@"touches ...");
 }
 */




- (void)didReceiveMemoryWarning {
  [ super didReceiveMemoryWarning ];
}


- (void)dealloc {
  NSLog(@"PageControllerViewController dealloc");
  NSLog(@"deviceRotation retain count = %d", [deviceRotation retainCount]);
  NSLog(@"source retain count = %d", [source retainCount]);
  PageScrollView *scrollView = (PageScrollView *)self.view;
  if(deviceRotation) {
    NSLog(@"deviceRotation retain count %d", [deviceRotation retainCount]);
    [deviceRotation release];
  }
  NSLog(@"scrollView retain count = %d", [scrollView retainCount]);
  [ scrollView release ];
  if(source)
    [source release];
  if(prevButton)
    [prevButton release];
  if(nextButton) 
    [nextButton release];
  if(toolbarButtons)
    [toolbarButtons release];
  [ super dealloc ];
}


#pragma mark Responding to Scrolling and Dragging

/*!
 @method scrollViewWillBeginDragging:
 @discussion Scroll開始の通知、前後ページのViewを非表示から表示の状態にする
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  NSLog(@"begin dragging");
  PageScrollView *pageView = (PageScrollView *)self.view;
  if(pageView.nextPage) {
    pageView.nextPage.view.hidden = NO;
  }
  if(pageView.prevPage) {
    pageView.prevPage.view.hidden = NO;
  }
}

/*!
 @method scrollViewDidEndDecelerating:
 Scroll完了時の通知,
 移動先が前ページ/次ページの場合、現在ページ番号(変数)の変更、
 前後ページの作成、不要ページのかたづけを行う。
 */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  PageScrollView *view = (PageScrollView *)scrollView;
  BOOL hidden = self.navigationController.toolbarHidden;
  CGPoint point = scrollView.contentOffset;
  // 次のページの移動
  if(point.x > scrollView.bounds.size.width || 
     view.curPageNumber == 0 && point.x >= scrollView.bounds.size.width)
      {
    NSLog(@"page count = %d", [source pageCount]);
    if(view.curPageNumber + 1 < [source pageCount] ) {
      [view toNextPage];
      if(view.curPageNumber + 1 < [source pageCount]) {
        UIViewController<ScrolledPageViewDelegate> *controller 
        = [source pageAt:view.curPageNumber + 1];
        [view setNextPage:controller];
        [controller pageDidAddWithPageScrollViewController:self
                                           withOrientation:orientation];
        [controller setPageController:self];
        controller.view.hidden = YES;
        [controller release];
        [view layoutViews];
        //[controller viewDidAppear:YES];
      }
      else {
        [view layoutViews];
        
      }
    }
      }
  // 前のページへの移動
  else if(point.x < scrollView.bounds.size.width) {
    if(view.curPageNumber > 0) {
      [view toPrevPage];
      if(view.curPageNumber > 0) {
        UIViewController<ScrolledPageViewDelegate> *controller 
        = [source pageAt:view.curPageNumber - 1];
        [view setPrevPage:controller];
        [controller pageDidAddWithPageScrollViewController:self withOrientation:orientation];
        [controller setPageController:self];
        controller.view.hidden = YES;
        [controller release];
        [view layoutViews];
      }
      else {
        [view layoutViews];
      }
    }
//    [view toCurPage];
    
  }
  PageScrollView *pageView = (PageScrollView *)self.view;
  if(pageView.nextPage) {
    pageView.nextPage.view.hidden = YES;
  }
  if(pageView.prevPage) {
    pageView.prevPage.view.hidden = YES;
  }
  [view layoutViews];
  // scrollViewのcontentのinsetとoffsetを調整(1回、描画処理に戻ってから呼ばれるようにする)
  [self performSelectorOnMainThread:@selector(resetScrollOffsetAndInset:) 
                         withObject:[NSNumber numberWithBool:hidden]
                      waitUntilDone:NO];
  
}

#pragma mark Public 

-(void) pageScrollViewDidChangeCurrentPage:(PageScrollView *)pageScrollView 
                               currentPage:(int)currentPage {
  NSLog(@"現在表示中のページ %d\n", currentPage);
}

-(void) changeNavigationAndStatusBar {
  // View階層のConsole出力
  /*
   UIView *v = self.view;
   NSLog(@"------ before -------");
   for(int i = 0; i < 5; ++i) {
   CGRect rect = v.frame;
   NSLog(@"Class = %@,Page view,x ==> %f, y => %f, width => %f, height => %f ",
   [v class],
   rect.origin.x , rect.origin.y, 
   rect.size.width, rect.size.height
   );
   v = v.superview;
   }
   */
  
  // 表示/非表示の反転
  BOOL hidden = !self.navigationController.navigationBar.hidden;
  self.navigationController.navigationBar.hidden = hidden;
  [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
  [self.navigationController setToolbarHidden:hidden];
  // View階層のConsole出力
  /*
   NSLog(@"------ after -------");
   v = self.view;
   for(int i = 0; i < 5; ++i) {
   CGRect rect = v.frame;
   NSLog(@"Class = %@,Page view,x ==> %f, y => %f, width => %f, height => %f ",
   [v class],
   rect.origin.x , rect.origin.y, 
   rect.size.width, rect.size.height
   );
   v = v.superview;
   }
   */
  // scrollViewのcontentのinsetとoffsetを調整(1回、描画処理に戻ってから呼ばれるようにする)
  [self performSelectorOnMainThread:@selector(resetScrollOffsetAndInset:) 
                         withObject:[NSNumber numberWithBool:hidden]
                      waitUntilDone:NO];
}


- (void)toNextPage:(id)sender {
  PageScrollView *scrollView = (PageScrollView *)self.view;
	[scrollView toNextPage];  
  if(scrollView.curPageNumber + 1 < [source pageCount]) {
    UIViewController<ScrolledPageViewDelegate> *controller 
    = [source pageAt:scrollView.curPageNumber + 1];
    [scrollView setNextPage:controller];
    [controller pageDidAddWithPageScrollViewController:self
                                       withOrientation:orientation];
    [controller setPageController:self];
    controller.view.hidden = YES;
    [controller release];
    //[controller viewDidAppear:YES];
  }
  [scrollView layoutViews];
  [self setToolbarStatus];
}

- (void)toPrevPage:(id)sender {
  PageScrollView *scrollView = (PageScrollView *)self.view;
	[scrollView toPrevPage];  
  if(scrollView.curPageNumber > 0) {
    UIViewController<ScrolledPageViewDelegate> *controller 
    = [source pageAt:scrollView.curPageNumber - 1];
    [scrollView setPrevPage:controller];
    [controller pageDidAddWithPageScrollViewController:self withOrientation:orientation];
    [controller setPageController:self];
    controller.view.hidden = YES;
    [controller release];
  }
  [scrollView layoutViews];
  [self setToolbarStatus];
}

#pragma mark Private Method

- (void)resetScrollOffsetAndInset:(id)arg {
  PageScrollView *scrollView = (PageScrollView *)self.view;
  UIEdgeInsets inset;
  inset.left = 0;
  inset.right = 0;
  inset.top = 0;
  inset.bottom = 0;
  scrollView.contentInset = inset;
  CGSize size = scrollView.contentSize;
  size.height = self.view.frame.size.height;
  scrollView.contentSize = size;
}

- (void)setToolbarStatus {
  PageScrollView *scrollView = (PageScrollView *)self.view;
  if(scrollView.curPageNumber + 1 < [source pageCount]) {
    nextButton.enabled = YES;
	} 
  else {
    nextButton.enabled = NO;
  }
  if(scrollView.curPageNumber > 0) {
   	prevButton.enabled = YES;
  }
  else {
    prevButton.enabled = NO;
  }
}

- (NSArray *) toolbarButtons {
  NSString *path;

  if(!toolbarButtons) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    toolbarButtons = [[NSMutableArray alloc] init];
    // Action
    UIBarButtonItem *action
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                    target:self
                                                    action:nil];
    [toolbarButtons addObject:action];
    [action release];

    
    // Space
    UIBarButtonItem *spaceLeft
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                    target:self
                                                    action:nil];
    spaceLeft.width = 30.0f;
    [toolbarButtons addObject:spaceLeft];
    [spaceLeft release];
    
    // Left
    prevButton = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                  style:UIBarButtonItemStyleBordered 
                                                 target:self
                                                 action:@selector(toPrevPage:)];
    path = [[NSBundle mainBundle] pathForResource:@"arrowleft" ofType:@"png"];
    prevButton.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:prevButton];

    // Space
    UIBarButtonItem *space 
    = [[UIBarButtonItem alloc] 
       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
       target:self
       action:nil];
		[toolbarButtons addObject:space];    
    [space release];
    
    // Right
    nextButton = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                  style:UIBarButtonItemStyleBordered 
                                                 target:self
                                                 action:@selector(toNextPage:)];
    path = [[NSBundle mainBundle] pathForResource:@"arrowright" ofType:@"png"];
    nextButton.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:nextButton];

    // Space
    UIBarButtonItem *spaceRight
    = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                    target:self
                                                    action:nil];
    spaceRight.width = 30.0f;
    [toolbarButtons addObject:spaceRight];
    [spaceRight release];

    // Info
    UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithTitle:@"" 
                                                              style:UIBarButtonItemStyleBordered 
                                                             target:self
                                                             action:nil];
    path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    info.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:info];
    [info release];
    
    [pool drain];
  }
  return toolbarButtons;
}

- (void) setCurPageNumber:(NSUInteger)n {
  PageScrollView *view = (PageScrollView *)self.view;
  view.curPageNumber = n;
}


- (NSUInteger) curPageNumber {
  PageScrollView *view = (PageScrollView *)self.view;
	return view.curPageNumber;
}


#pragma mark DeviceRotationDelegate

-(void) deviceRotated:(UIDeviceOrientation)orient {
  NSLog(@"device ROtated");
  // 回転処理中は、表示位置がずれないようにtoolbarを非表示にする、最後に現在の状態(表示/非表示)に戻す
  BOOL hidden =   self.navigationController.toolbarHidden;
  self.navigationController.toolbarHidden = YES;
  
  // Navigation barの位置設定,StatusBarの下へ
  /*
   CGRect barFrame = self.navigationController.navigationBar.frame;
   CGRect frame = [[UIScreen mainScreen] bounds];
   self.navigationController.view.frame = frame;
   barFrame.origin.y = statusBarHeight;
   self.navigationController.navigationBar.frame = barFrame;
   */
  // View階層のConsole出力
  UIView *v = self.view;
  for(int i = 0; i < 5; ++i) {
    CGRect rect = v.frame;
    NSLog(@"Class = %@,Page view,x ==> %f, y => %f, width => %f, height => %f ",
          [v class],
          rect.origin.x , rect.origin.y, 
          rect.size.width, rect.size.height
          );
    v = v.superview;
  }
  
  //
  orientation = orient;
  // Page Viewのサイズ設定
  PageScrollView *scrollView = (PageScrollView *)self.view;
  if(source) {
    NSUInteger count = [source pageCount];
    [scrollView setPageCount:count];
  }	
  // Page View のLayout
//  [scrollView toCurPage];
  [scrollView layoutViews];
  // Page要素への通知
  if(scrollView.curPage) {
    [scrollView.curPage pageScrollView:self rotated:orientation];
  }
  if(scrollView.nextPage) {
    [scrollView.nextPage pageScrollView:self rotated:orientation];
  }
  if(scrollView.prevPage) {
    [scrollView.prevPage pageScrollView:self rotated:orientation];
  }
  //  self.wantsFullScreenLayout = YES;
  self.navigationController.toolbarHidden = hidden;
  [self performSelectorOnMainThread:@selector(resetScrollOffsetAndInset:) 
                         withObject:[NSNumber numberWithBool:hidden]
                      waitUntilDone:NO];
  
}


@end
