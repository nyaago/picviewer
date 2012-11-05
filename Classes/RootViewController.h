//
//  RootViewController.h
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

#import "NewUserViewController.h"
#import "PicasaFetchController.h"
#import "LabeledActivityIndicator.h"

/*!
 @class RootViewController
 RootのView. ユーザの一覧を表示するView
 */
@interface RootViewController : UITableViewController 
<NSFetchedResultsControllerDelegate,NewUserViewControllerDeleate, 
PicasaFetchControllerDelegate, LabeledActivityIndicatorDelegate> {
  NSFetchedResultsController *fetchedUsersController;
  
  NSManagedObjectContext *managedObjectContext;
  
  UIBarButtonItem *addButton;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;
  // 削除処理中のindicator
  LabeledActivityIndicator *indicatorView;
  // 最初の表示であればYES;
  BOOL firstAppearance;
}

/*!
 @prooerty fetchedUsersController
 @discussion User一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedUsersController;
/*!
 @prooerty NSManagedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method settingsAction:
 @discussion 設定ボタンのアクション、設定Viewの表示
 */
- (void) settingsAction:(id)sender;


@end
