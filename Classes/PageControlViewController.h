#import <UIKit/UIKit.h>

#import "DeviceRotation.h"

@protocol ScrolledPageViewDelegate;



/*!
 @class PageScrollView
 @discussion PageControllViewの内部で使用されるScrollでPageが切り替えられるView
 @TODO Privateにするか..
 */
@interface PageScrollView : UIScrollView <UIScrollViewDelegate> {
  @private
  // ページ数
  NSUInteger   pageCount;
  // 現在のページ番号
  NSUInteger   curPageNumber;
  // 現在ページのViewのController
  UIViewController<ScrolledPageViewDelegate>	   *curPage;
  // 次のページのViewのController
  UIViewController<ScrolledPageViewDelegate>	   *nextPage;
  // 前のページのViewのController
  UIViewController<ScrolledPageViewDelegate>	   *prevPage;
}

/*!
 @property nextPage
 @discussion 次のページ
 */
@property (nonatomic, retain) UIViewController<ScrolledPageViewDelegate> *nextPage;
/*!
 @property curPage
 @discussion 現在の表示ページ
 */
@property (nonatomic, retain) UIViewController<ScrolledPageViewDelegate> *curPage;
/*!
 @property prevPage
 @discussion 前のページ
 */
@property (nonatomic, retain) UIViewController<ScrolledPageViewDelegate> *prevPage;

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
 @class PageScrollView
 @discussion ページめくりのできるScrollViewのController
 */
@protocol PageControlViewControllerDataSource;
@interface PageControlViewController : UIViewController 
< UIScrollViewDelegate, DeviceRotationDelegate> {
  
  @private
  // ページに表示するViewを提供するソースオブジェクト
  UIViewController<PageControlViewControllerDataSource> *source;
  // 現在ページ - @TODO - Viewから取得する..
 // NSUInteger curPageNumber;
  // 機器回転通知の管理オブジェクト
  DeviceRotation  *deviceRotation;
  // 現在の機器の向き
  UIDeviceOrientation orientation;
  // Statusbarの高さ
  NSUInteger statusBarHeight;
  // toolbarのボタンの配列
  NSMutableArray *toolbarButtons;
  // 次ページ表示ボタン
  UIBarButtonItem *nextButton;
  // 前ページ表示ボタン
  UIBarButtonItem *prevButton;
}

/*!
 @property source
 @discussion ページに表示するViewを提供するソースオブジェクト
 */
@property (nonatomic, retain) UIViewController<PageControlViewControllerDataSource> *source;

/*!
 @property curPageNumber
 @discussion 現在ページ番号
 */
@property (nonatomic) NSUInteger curPageNumber;

/*!
 @method pageScrollViewDidChangeCurrentPage:currentPage: 
 @discussion Page変更時の処理(現在ダミー)
 */
-(void) pageScrollViewDidChangeCurrentPage:(PageScrollView *)pageScrollView 
                               currentPage:(int)currentPage;

/*!
 @method changeNavigationAndStatusBar
 @discussion NavigationBarとStatusBarの表示状態の切り替え(表示<->非表示>
 */
-(void) changeNavigationAndStatusBar;


/*!
 @method toNextPage
 @discussion 次のページを現在ページへ
 */
- (void)toNextPage:(id)sender;

/*!
 @method toPrevPage
 @discussion 前のページを現在ページへ
 */
- (void)toPrevPage:(id)sender;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method setCurPageNumber
 @discussion 現在ページの設定
 */
- (void) setCurPageNumber:(NSUInteger)n;

/*!
 @method curPageNumber
 @discussion 現在ページ
 */
- (NSUInteger) curPageNumber;



@end


/*!
 @protocal ScrolledPageViewDelegate
 @discussion ScrollされるPageへのDelegateのProtocol
 */
@protocol ScrolledPageViewDelegate 

/*!
 @method pageDidAddWithPageScrollViewController:withOrientation:
 @discussion Pageに追加されたときの通知、追加されたviewControllerに対して、
 viewWillAppear:animated,viewDidAppearが通知されないので、
 そこで必要とされるような処理を実装する。
 @param controller 通知元のPageControllViewController
 @param orientation 向き(UIDeviceOrientation)
 */
- (void) pageDidAddWithPageScrollViewController:(PageControlViewController *)controller
                                withOrientation:(UIDeviceOrientation)orientation;

/*!
 @method pageScrollView:rotated:
 @discussion 機器がRotateした場合の通知
 @param controller 通知元のPageControllViewController
 @param orientation 向き(UIDeviceOrientation)
 */
- (void) pageScrollView:(PageControlViewController *)controller 
                rotated:(UIDeviceOrientation)orientation;




/*!
 @method setPageController
 
 */
- (void) setPageController:(PageControlViewController *)controller;

@optional

/*!
	@method viewInfoAction:
 	@discussion 情報表示のボタンのアクション
 */
- (void) viewInfoAction:(PageControlViewController *)sender;

@end


/*!
 @protocal PageControlViewControllerDataSource
 @discussion 各ページのViewControllerのインスタンスを提供するデータソースのProtocol
 @TODO 名称変更 PageControlViewControllerDelegate -> PageControlViewControllerSource
 */
@protocol PageControlViewControllerDataSource

/*!
 @method pageCount
 @discussion ページ数を返す
 */
- (NSUInteger) pageCount;

/*!
 @method pageAt:
 @discussion 指定したページのViewControllerを返す
 @param n 0起点のページ番号
 */
- (UIViewController<ScrolledPageViewDelegate> *) pageAt:(NSUInteger)n;


@end


