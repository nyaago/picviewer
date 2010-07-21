#import <UIKit/UIKit.h>

#import "DeviceRotation.h"

@protocol PageViewDelegate;
@protocol PageControlViewControllerDataSource;
@class PageView;

/*!
 @class PageView
 @discussion ページめくりのできるScrollViewのController
 */
@interface PageControlViewController : UIViewController 
< UIScrollViewDelegate, DeviceRotationDelegate> {
  
  @private
  // ページに表示するViewを提供するソースオブジェクト
  NSObject<PageControlViewControllerDataSource> *source;
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
@property (nonatomic, retain) NSObject<PageControlViewControllerDataSource> *source;


/*!
 @property curPageNumber
 @discussion 現在ページ番号
 */
@property (nonatomic) NSUInteger curPageNumber;

/*!
 @method pageViewDidChangeCurrentPage:currentPage: 
 @discussion Page変更時の処理(現在ダミー)
 */
-(void) pageViewDidChangeCurrentPage:(PageView *)pageView 
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

/*!
 @method pageCount
 @discussion ページ数を返す
 */
- (NSUInteger) pageCount;


@end


/*!
 @protocal PageViewDelegate
 @discussion ScrollされるPageへのDelegateのProtocol
 */
@protocol PageViewDelegate 

/*!
 @method pageDidAddWithPageViewController:withOrientation:
 @discussion Pageに追加されたときの通知、追加されたviewControllerに対して、
 viewWillAppear:animated,viewDidAppearが通知されないので、
 そこで必要とされるような処理を実装する。
 @param controller 通知元のPageControllViewController
 @param orientation 向き(UIDeviceOrientation)
 */
- (void) pageDidAddWithPageViewController:(PageControlViewController *)controller
                                withOrientation:(UIDeviceOrientation)orientation;

/*!
 @method pageView:rotated:
 @discussion 機器がRotateした場合の通知
 @param controller 通知元のPageControllViewController
 @param orientation 向き(UIDeviceOrientation)
 */
- (void) pageView:(PageControlViewController *)controller 
                rotated:(UIDeviceOrientation)orientation;


/*!
 @method setPageController
 @discuttion PageViewのコントローラーを設定
 */
- (void) setPageController:(PageControlViewController *)controller;


@optional

/*!
	@method viewInfoAction:
 	@discussion 情報表示のボタンのアクション
 */
- (void) viewInfoAction:(PageControlViewController *)sender;

/*!
 @method viewInfoAction:
 @discussion Actionボタンのアクション
 */
- (void) doAction:(PageControlViewController *)sender;

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
- (UIViewController<PageViewDelegate> *) pageAt:(NSUInteger)n;

@optional


@end

