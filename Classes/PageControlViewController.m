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

/*!
 @method doAction:
 @discussion 情報ボタンを押したさいのAction
 Delegate Methodへの委譲を行う.
 */
- (void)infoAction:(id)sender;

/*!
 @method doAction:
 @discussion actionボタンを押したさいのAction
 Delegate Methodへの委譲を行う.
 */
- (void)doAction:(id)sender;


/*!
 @method setNavifationTitle
 @discussion Navigation Bar のタイトル(現在ページ/ページ数)の設定
 */
- (void)setNavigationTitle;

@end

/*!
 @class PageView
 @discussion PageControllViewの内部で使用されるScrollでPageが切り替えられるView
 */
@interface PageView : UIScrollView <UIScrollViewDelegate> {
@private
  // ページ数
  NSUInteger   pageCount;
  // 現在のページ番号
  NSUInteger   curPageNumber;
  // 現在ページのViewのController
  UIViewController<PageViewDelegate>	   *curPage;
  // 次のページのViewのController
  UIViewController<PageViewDelegate>	   *nextPage;
  // 前のページのViewのController
  UIViewController<PageViewDelegate>	   *prevPage;
}

/*!
 @property nextPage
 @discussion 次のページ
 */
@property (nonatomic, retain) UIViewController<PageViewDelegate> *nextPage;
/*!
 @property curPage
 @discussion 現在の表示ページ
 */
@property (nonatomic, retain) UIViewController<PageViewDelegate> *curPage;
/*!
 @property prevPage
 @discussion 前のページ
 */
@property (nonatomic, retain) UIViewController<PageViewDelegate> *prevPage;


/*!
 @property curPageNumber
 @discussion 現在ページ番号(0基点)
 */
@property (nonatomic) NSUInteger curPageNumber;


/*!
 @method setPageCount:
 @discussion ページ数を設定
 @param ページ数
 */
- (void)setPageCount:(NSUInteger)n;

/*!
 @method pointForCurPage
 @return 現在ページの座標を返す
 */
- (CGPoint) pointForCurPage;

/*!
 @method setCurPage:withPageNumber:
 @discussion 現在ページのViewControllerを設定
 @param newView 設定するViewController
 @param n ページ番号(0起点)
 */
- (void)setCurPage:(UIViewController *)newView withPageNumber:(NSUInteger)n;

/*!
 @method setNextPage:
 @discussion 次ページのViewControllerを設定
 @param newView 設定するViewController
 */
- (void)setNextPage:(UIViewController *)newView;

/*!
 @method setPrevPage:
 @discussion 前ページのViewControllerを設定
 @param newView 設定するViewController
 */
- (void)setPrevPage:(UIViewController *)newView;

/*!
 @method toCurPage
 @discussion 現在ページを表示
 */
//- (void)toCurPage;

/*!
 @method toNextPage
 @discussion 次のページを現在ページへ
 */
- (UIViewController *)toNextPage;

/*!
 @method toPrevPage
 @discussion 前のページを現在ページへ
 */
- (UIViewController *)toPrevPage;

/*!
 @method layoutViews
 @discussion 各View(前後ページ、現在ページ）のレイアウトを行う
 */
- (void)layoutViews;


/*!
 @method removeCurPage
 @discussion 現在ページを取り除く
 */
- (void)removeCurPage;

/*!
 @method removeNextPage
 @discussion 次ページを取り除く
 */
- (void)removeNextPage;

/*!
 @method removePrevPage
 @discussion 前ページを取り除く
 */
- (void)removePrevPage;

@end



/*!
 @class PageView
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
  
  // Page View 生成して階層に追加
  CGRect scrollViewBounds = [[UIScreen mainScreen] bounds];
  PageView *pageView = [ [ PageView alloc ] 
                                initWithFrame:scrollViewBounds];
  pageView.delegate = self;
  self.view = pageView;

}

/*!
 @method viewDidLoad
 @discussion Viewロードの通知
 */
- (void)viewDidLoad {
  NSLog(@"PageControllerViewController view Did Load ratain count = %d", 
        [self retainCount]);
  // backボタンがない場合(iPadの場合）
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
  // 機器の向き、初期は縦向きに
  orientation = UIDeviceOrientationPortrait;
  // toolbar設定
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
  PageView *scrollView = (PageView *)self.view;
  [scrollView removeCurPage];
  [scrollView removeNextPage];
  [scrollView removePrevPage];
}

/*!
 @method viewDidAppear:
 @discussion Viewが表示されたときの通知.
 機器回転の関知開始、navigation/status/tool - barの設定,各ページの追加/設定
 */
- (void)viewDidAppear:(BOOL)animated {
  
  [super viewDidAppear:animated];
  
  // navigationのtopでない場合は、backボタン追加
  if([[self.navigationController viewControllers] count] == 1 && self.parentViewController != nil) {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle:NSLocalizedString(@"Photos", @"Photos")
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:@selector(backAction:) ];
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton  autorelease];
  }

  NSLog(@"PageControllerViewController view Did Appear ratain count = %d",
        [self retainCount]);
  
  //  [super viewDidLoad];
  // デバイス回転の管理開始
  if(!deviceRotation) {
    deviceRotation = [[DeviceRotation alloc] initWithDelegate:self];
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
  PageView *pageView = (PageView *)self.view;
  if(source) {
    NSUInteger count = [source pageCount];
    [pageView setPageCount:count];
    // 現在ページ追加
    if(pageView.curPageNumber < count) {
      UIViewController<PageViewDelegate> *controller 
      = [source pageAt:pageView.curPageNumber];
      [controller setPageController:self];
      [pageView setCurPage:controller withPageNumber:pageView.curPageNumber];
      [controller pageDidAddWithPageViewController:self 
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller release];
      
      //  [controller viewDidAppear:YES];
    }
    // 次ページ
    if(pageView.curPageNumber + 1 < count) {
      UIViewController<PageViewDelegate> *controller 
      = [source pageAt:pageView.curPageNumber + 1];
      [pageView setNextPage:controller];
      [controller pageDidAddWithPageViewController:self
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller setPageController:self];
      controller.view.hidden = YES;
      [controller release];
    }
    // 前ページ
    if(pageView.curPageNumber > 0) {
      UIViewController<PageViewDelegate> *controller 
      = [source pageAt:pageView.curPageNumber - 1];
      [pageView setPrevPage:controller];
      [controller pageDidAddWithPageViewController:self
                                         withOrientation:UIDeviceOrientationPortrait];
      [controller setPageController:self];
      controller.view.hidden = YES;
      [controller release];
    }
  }
  // pageView内のviewのLayout
  [pageView layoutViews];
  // Toolbarのボタンの状態設定
  [self setToolbarStatus];
  [self setNavigationTitle];
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

/*!
 @method shouldAutorotateToInterfaceOrientation:
 @discussion 機器回転時に自動的にView回転を行うかの判定.
 自動的に回転されるように、常にYESを返す。
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
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
  PageView *pageView = (PageView *)self.view;
  if(deviceRotation) {
    NSLog(@"deviceRotation retain count %d", [deviceRotation retainCount]);
    [deviceRotation release];
  }
  NSLog(@"pageView retain count = %d", [pageView retainCount]);
  [ pageView release ];
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
  PageView *pageView = (PageView *)self.view;
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
  PageView *view = (PageView *)scrollView;
  BOOL hidden = self.navigationController.toolbarHidden;
  CGPoint point = scrollView.contentOffset;
  // 次のページの移動時
  if(point.x > scrollView.bounds.size.width || 
     view.curPageNumber == 0 && point.x >= scrollView.bounds.size.width) {
    NSLog(@"page count = %d", [source pageCount]);
    if(view.curPageNumber + 1 < [source pageCount] ) {
   //   [view toNextPage];
      if(view.curPageNumber + 1 < [source pageCount]) {
				[self toNextPage:self];        
      }
      else {
        [view layoutViews];
        
      }
    }
  }
  // 前のページへの移動時
  else if(point.x < scrollView.bounds.size.width) {
    if(view.curPageNumber > 0) {
  //    [view toPrevPage];
      if(view.curPageNumber > 0) {
        [self toPrevPage:self];
      }
      else {
        [view layoutViews];
      }
    }
  }
  PageView *pageView = (PageView *)self.view;
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

-(void) pageViewDidChangeCurrentPage:(PageView *)pageView 
                               currentPage:(int)currentPage {
  NSLog(@"現在表示中のページ %d\n", currentPage);
}

-(void) changeNavigationAndStatusBar {

  // 表示/非表示の反転
  BOOL hidden = !self.navigationController.navigationBar.hidden;
  if([UIApplication 
      instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
  	[[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:YES];
  }
	else {		// OS 3.2未満用
	  [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:YES];
  }
  self.navigationController.navigationBar.hidden = hidden;
  CGRect frame = self.navigationController.navigationBar.frame;
  frame.origin.y = statusBarHeight;
  self.navigationController.navigationBar.frame = frame;
//  [[self.navigationController navigationBar] setHidden:hidden];
  [self.navigationController setNavigationBarHidden:hidden animated:hidden];
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
  PageView *scrollView = (PageView *)self.view;
	[scrollView toNextPage];  
  if(scrollView.curPageNumber + 1 < [source pageCount]) {
    UIViewController<PageViewDelegate> *controller 
    = [source pageAt:scrollView.curPageNumber + 1];
    [scrollView setNextPage:controller];
    [controller pageDidAddWithPageViewController:self
                                       withOrientation:orientation];
    [controller setPageController:self];
    controller.view.hidden = YES;
    [controller release];
    //[controller viewDidAppear:YES];
  }
  [scrollView layoutViews];
  [self setToolbarStatus];
  [self setNavigationTitle];
}

- (void)toPrevPage:(id)sender {
  PageView *scrollView = (PageView *)self.view;
	[scrollView toPrevPage];  
  if(scrollView.curPageNumber > 0) {
    UIViewController<PageViewDelegate> *controller 
    = [source pageAt:scrollView.curPageNumber - 1];
    [scrollView setPrevPage:controller];
    [controller pageDidAddWithPageViewController:self withOrientation:orientation];
    [controller setPageController:self];
    controller.view.hidden = YES;
    [controller release];
  }
  [scrollView layoutViews];
  [self setToolbarStatus];
  [self setNavigationTitle];
}

- (void)infoAction:(id)sender {
  PageView *scrollView = (PageView *)self.view;
  if([scrollView.curPage respondsToSelector:@selector(viewInfoAction:)]) {
    [scrollView.curPage viewInfoAction:self];
  }
}

- (void)doAction:(id)sender {
  PageView *scrollView = (PageView *)self.view;
  if([scrollView.curPage respondsToSelector:@selector(doAction:)]) {
    [scrollView.curPage doAction:self];
  }
}

- (void) setCurPageNumber:(NSUInteger)n {
  PageView *view = (PageView *)self.view;
  view.curPageNumber = n;
}


- (NSUInteger) curPageNumber {
  PageView *view = (PageView *)self.view;
	return view.curPageNumber;
}

- (NSUInteger) pageCount {
  if(self.source) {
    return [source pageCount];
  }
  return 0;
}

- (void) backAction:(PageControlViewController *)sender {
  [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark -

#pragma mark Private Method

- (void)resetScrollOffsetAndInset:(id)arg {
  PageView *scrollView = (PageView *)self.view;
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
  PageView *scrollView = (PageView *)self.view;
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

- (void)setNavigationTitle {
  NSString *title = [NSString stringWithFormat:@"%d/%d", 
                     self.curPageNumber + 1, [self pageCount]];
  self.navigationItem.title = title;
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
                                                    action:@selector(doAction:)];
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
                                                             action:@selector(infoAction:)];
    path = [[NSBundle mainBundle] pathForResource:@"newspaper" ofType:@"png"];
    info.image = [[UIImage alloc] initWithContentsOfFile:path];
    [toolbarButtons addObject:info];
    [info release];
    
    [pool drain];
  }
  return toolbarButtons;
}

#pragma mark -

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
  PageView *scrollView = (PageView *)self.view;
  if(source) {
    NSUInteger count = [source pageCount];
    [scrollView setPageCount:count];
  }	
  // Page View のLayout
//  [scrollView toCurPage];
  [scrollView layoutViews];
  // Page要素への通知
  if(scrollView.curPage) {
    [scrollView.curPage pageView:self rotated:orientation];
  }
  if(scrollView.nextPage) {
    [scrollView.nextPage pageView:self rotated:orientation];
  }
  if(scrollView.prevPage) {
    [scrollView.prevPage pageView:self rotated:orientation];
  }
  //  self.wantsFullScreenLayout = YES;
  self.navigationController.toolbarHidden = hidden;
  [self performSelectorOnMainThread:@selector(resetScrollOffsetAndInset:) 
                         withObject:[NSNumber numberWithBool:hidden]
                      waitUntilDone:NO];
  
}


@end



@implementation PageView

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


- (void)dealloc {
  NSLog(@"PageView dealloc");
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

