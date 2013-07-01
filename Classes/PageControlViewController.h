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
  // 機器回転通知の管理オブジェクト
  DeviceRotation  *deviceRotation;
  // 
  BOOL initialLayout;
  // 現在のレイアウトの向き
  UIDeviceOrientation layoutedOrientation;
  // Statusbarの高さ
  NSUInteger statusBarHeight;
  // toolbarのボタンの配列
  NSMutableArray *toolbarButtons;
  // 次ページ表示ボタン
  UIBarButtonItem *nextButton;
  // 前ページ表示ボタン
  UIBarButtonItem *prevButton;
  //
  PageView *pageView;
}

/*!
 @property source
 @discussion ページに表示するViewを提供するソースオブジェクト
 */
@property (nonatomic, assign) NSObject<PageControlViewControllerDataSource> *source;


/*!
 @property curPageNumber
 @discussion 現在ページ番号
 */
@property (nonatomic) NSUInteger curPageNumber;

/*!
 @property pageView
 @discussion paging 用 view
 */
@property (nonatomic, retain) PageView *pageView;

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

/*!
 @method backAction:
 @discussion 前頁へ戻る(iPad）
 */


- (void) backAction:(PageControlViewController *)sender;


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

/*!
 @method isCompleted
 @discussion この画面のデーターのロードなどが完了しているか
 */
- (BOOL) isCompleted;


/*!
 @meothd canDiscard
 @discussion この画面を破棄してもよいかの判定
 @return 破棄してもOKならYESを返す
 */
- (BOOL) canDiscard;

/*!
 @method requireToDiscard
 @discussion 破棄のための準備を指示
 */
- (void) requireToDiscard;


@optional

/*!
 @method movedToCurrentInPageView:
 @discussion このviewが現在の表示対象ページとなった場合の通知
 */
- (void) movedToCurrentInPageView:(PageControlViewController *)controller;


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

