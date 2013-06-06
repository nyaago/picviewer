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

/*!
 @method refreshView
 */
- (void) refreshViewWithDiviceOrientation:(UIDeviceOrientation)orientation;

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
- (void)setCurPage:(UIViewController<PageViewDelegate> *)newView withPageNumber:(NSUInteger)n;

/*!
 @method setNextPage:
 @discussion 次ページのViewControllerを設定
 @param newView 設定するViewController
 */
- (void)setNextPage:(UIViewController<PageViewDelegate> *)newView;

/*!
 @method setPrevPage:
 @discussion 前ページのViewControllerを設定
 @param newView 設定するViewController
 */
- (void)setPrevPage:(UIViewController<PageViewDelegate> *)newView;


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
@synthesize pageView;
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
  
}

/*!
 @method viewDidLoad
 @discussion Viewロードの通知
 */
- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  // Page View 生成して階層に追加
  CGRect scrollViewBounds = [[UIScreen mainScreen] bounds];
  PageView *view = [[ [ PageView alloc ]
                        initWithFrame:scrollViewBounds] autorelease];
  view.delegate = self;
  self.view = view;
  self.pageView = view;
  [pool drain];
}


/*!
 @method viewDidLayoutSubviews
 @discussion sub view のレイアウトがされたときの通知
 機器の向きが変更されていれば、　sub view のリフレッシュ（サイズ、位置変更）を行う。
 */
- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  // 最初のレイアウト描画時であれば何もしない
  if(initialLayout) {
    initialLayout = NO;
    return;
  }
  // 向きが変わっていなければ何もしない
  if([[UIDevice currentDevice] orientation] == layoutedOrientation) {
    return;
  }
  [self refreshViewWithDiviceOrientation:[[UIDevice currentDevice]orientation]];
}

/*!
 @method viewWillAppear:
 @discussion viewが表示される前の通知、toolbarの表示とViewの全画面表示の設定
 */
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
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
  [super viewDidDisappear:animated];
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
  
  // navigationのtopでない場合(iPad)は、backボタン追加
  if([[self.navigationController viewControllers] count] == 1 && self.parentViewController != nil) {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithTitle:NSLocalizedString(@"Photos", @"Photos")
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:@selector(backAction:) ];
    self.navigationItem.leftBarButtonItem = backButton;
    [backButton  autorelease];
  }

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
  // Page追加
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
  layoutedOrientation = UIDeviceOrientationPortrait;
  initialLayout = YES;  
  // Toolbarのボタンの状態設定
  [self setToolbarStatus];
  [self setNavigationTitle];
}

/*!
 @method viewWillDisappear: 
 */
- (void)viewWillDisappear:(BOOL)animated {
  [deviceRotation release];
  deviceRotation = nil;
  // 下位view の破棄
  if(self.pageView.curPage) {
    [self.pageView.curPage requireToDiscard];
  }
  if(self.pageView.nextPage) {
    [self.pageView.nextPage requireToDiscard];
  }
  if(self.pageView.prevPage) {
    [self.pageView.prevPage requireToDiscard];
  }
  
  if(self.pageView.curPage) {
    if([self.pageView.curPage canDiscard] == NO) {
      return;
    }
  }
  if(self.pageView.nextPage) {
    if([self.pageView.nextPage canDiscard] == NO) {
      return;
    }
  }
  if(self.pageView.prevPage) {
    if([self.pageView.prevPage canDiscard] == NO) {
      return;
    }
  }

  
}

#pragma mark -

#pragma mark Device Rotation

/*!
 機器回転時に自動的にView回転を行うかの判定.
 自動的に回転されるように、常にYESを返す。
 */
- (BOOL)shouldAutorotate {
  return YES;
}

/*!
 サポートされている機器の向き
 すべてサポート
 */
- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}

/*!
 ios5まで用.
 自動的に回転されるように、常にYESを返す。
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

#pragma mark -

#pragma mark Memory Management


- (void)didReceiveMemoryWarning {
  [ super didReceiveMemoryWarning ];
  if(prevButton) {
    [prevButton release];
    prevButton = nil;
  }
  if(nextButton) {
    [nextButton release];
    nextButton = nil;
  }
  if(toolbarButtons) {
    [toolbarButtons release];
    nextButton = nil;
  }
  if(pageView) {
    [ pageView release ];
    self.view = nil;
  }

}


- (void)dealloc {
//  PageView *pageView = (PageView *)self.view;
//  if(pageView) {
//    [ pageView release ];
//  }
  if(pageView) {
    [pageView release];
  }
  if(deviceRotation) {
    [deviceRotation release];
  }
  if(prevButton)
    [prevButton release];
  if(nextButton) 
    [nextButton release];
  if(toolbarButtons)
    [toolbarButtons release];
  [ super dealloc ];
}

#pragma mark -

#pragma mark Responding to Scrolling and Dragging

/*!
 @method scrollViewWillBeginDragging:
 @discussion Scroll開始の通知、前後ページのViewを非表示から表示の状態にする
 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  NSLog(@"begin dragging");
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
     (view.curPageNumber == 0 && point.x >= scrollView.bounds.size.width)) {
    NSLog(@"page count = %d", [source pageCount]);
    if(view.curPageNumber + 1 < [source pageCount] ) {
      if(view.curPageNumber + 1 < [source pageCount]) {
				[self toNextPage:self];        
      }
    }
  }
  // 前のページへの移動時
  else if(point.x < scrollView.bounds.size.width) {
    if(view.curPageNumber > 0) {
      if(view.curPageNumber > 0) {
        [self toPrevPage:self];
      }
    }
  }
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

-(void) changeNavigationAndStatusBar {

  // 表示/非表示の反転
  BOOL hidden = !self.navigationController.navigationBar.hidden;
  if([UIApplication 
      instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
  	[[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:YES];
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
  if(scrollView.curPageNumber + 1 >= [source pageCount]) {
    return;
  }
  if(scrollView.prevPage != nil) {
    [scrollView.prevPage waitUntilCompleted];
  }
  if(scrollView.curPage != nil ) {
    [scrollView.curPage waitUntilCompleted];
  }
	[scrollView toNextPage];
  UIViewController<PageViewDelegate> *controller
  = [source pageAt:scrollView.curPageNumber + 1];
  [scrollView setNextPage:controller];
  [controller pageDidAddWithPageViewController:self
                                     withOrientation:layoutedOrientation];
  [controller setPageController:self];
  controller.view.hidden = YES;
  [controller release];
  [scrollView layoutViews];
  [self setToolbarStatus];
  [self setNavigationTitle];
}

- (void)toPrevPage:(id)sender {
  PageView *scrollView = (PageView *)self.view;
  if(scrollView.curPageNumber <= 0) {
    return;
  }
  if(scrollView.nextPage != nil) {
    [scrollView.nextPage waitUntilCompleted];
  }
  if(scrollView.curPage != nil ) {
    [scrollView.curPage waitUntilCompleted];
  }
	[scrollView toPrevPage];
  UIViewController<PageViewDelegate> *controller
  = [source pageAt:scrollView.curPageNumber - 1];
  [scrollView setPrevPage:controller];
  [controller pageDidAddWithPageViewController:self
                               withOrientation:layoutedOrientation];
  [controller setPageController:self];
  controller.view.hidden = YES;
  [controller release];
  [scrollView layoutViews];
  [self setToolbarStatus];
  [self setNavigationTitle];
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

#pragma mark -

#pragma mark Action

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


- (void) backAction:(PageControlViewController *)sender {
  // 下位view の破棄
  if(self.pageView.curPage) {
    [self.pageView.curPage requireToDiscard];
  }
  if(self.pageView.nextPage) {
    [self.pageView.nextPage requireToDiscard];
  }
  if(self.pageView.prevPage) {
    [self.pageView.prevPage requireToDiscard];
  }

  if(self.pageView.curPage) {
    if([self.pageView.curPage canDiscard] == NO) {
      return;
    }
  }
  if(self.pageView.nextPage) {
    if([self.pageView.nextPage canDiscard] == NO) {
      return;
    }
  }
  if(self.pageView.prevPage) {
    if([self.pageView.prevPage canDiscard] == NO) {
      return;
    }
  }
  // ====
  
  [[self navigationItem] setLeftBarButtonItem:nil];
  [[self presentingViewController] dismissViewControllerAnimated:YES completion:^{;
  }];
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

- (void) refreshViewWithDiviceOrientation:(UIDeviceOrientation)orient {
  PageView *scrollView = (PageView *)self.view;
  BOOL hidden =   self.navigationController.toolbarHidden;
  self.navigationController.toolbarHidden = YES;
  
  // Page Viewのサイズ設定
  if(source) {
    NSUInteger count = [source pageCount];
    [scrollView setPageCount:count];
  }
  // Page View のLayout
  [scrollView layoutViews];
  // Page要素への通知
  if(scrollView.curPage) {
    [scrollView.curPage pageView:self rotated:orient];
  }
  if(scrollView.nextPage) {
    [scrollView.nextPage pageView:self rotated:orient];
  }
  if(scrollView.prevPage) {
    [scrollView.prevPage pageView:self rotated:orient];
  }
  //  self.wantsFullScreenLayout = YES;
  self.navigationController.toolbarHidden = hidden;
  layoutedOrientation = orient;
  [self performSelectorOnMainThread:@selector(resetScrollOffsetAndInset:)
                         withObject:[NSNumber numberWithBool:hidden]
                      waitUntilDone:NO];
  

}

#pragma mark -

#pragma mark DeviceRotationDelegate

-(void) deviceRotated:(UIDeviceOrientation)orient {
  NSLog(@"device ROtated");
  // 回転処理中は、表示位置がずれないようにtoolbarを非表示にする、最後に現在の状態(表示/非表示)に戻す
  if(layoutedOrientation == [[UIDevice currentDevice]orientation] ) {
    return;
  }
}


@end



@implementation PageView

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

- (void)setCurPage:(UIViewController<PageViewDelegate> *)newView withPageNumber:(NSUInteger)n {
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

- (void)setNextPage:(UIViewController<PageViewDelegate> *)newView {
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

- (void)setPrevPage:(UIViewController<PageViewDelegate> *)newView {
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


- (UIViewController *)toNextPage {
  // page入れ替え
  UIViewController<PageViewDelegate> *tmp; // 交換用
  UIViewController *popedView;
  tmp = curPage;
  curPage = nextPage;
  curPage.view.hidden = NO;
  popedView = prevPage;
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
  // page入れ替え
  UIViewController<PageViewDelegate> *tmp;
  UIViewController *popedView;
  tmp = curPage;
  curPage = prevPage;
  curPage.view.hidden = NO;
  popedView = nextPage;
  nextPage = nil;
  nextPage = tmp;
  prevPage = nil;
  curPageNumber -= 1;
  // 再表示
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
  [self removeCurPage];
  [self removePrevPage];
  [self removeNextPage];
  [super dealloc];
}

@end

