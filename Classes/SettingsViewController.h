//
//  SettingsViewController.h
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

#import <UIKit/UIKit.h>
#import "SettingsManager.h"
#import "PicasaFetchController.h"

@interface SettingsViewController : UITableViewController 
<PicasaFetchControllerDelegate> {
  @private
  UIBarButtonItem *completeButton;
  // 設定情報
  SettingsManager *settings;

  UITextField *userTextField;
  UITextField *passwordTextField;
  // 画像size 指定のControl
  UISegmentedControl *sizeControl;
}

/*!
 @method completeAction:
 @discussion 完了ボタンのアクション、入力内容を保存してViewを閉じる
 Networkの接続が可能であれば、入力アカウントが有効であるのチェックも行う。
 */
- (void) completeAction:(id)sender;


/*!
 @method userDidEndEditing:
 @discussion userId編集完了時の通知,値の保存を行う.
 */
- (void) userDidEndEditing:(id)sender;

/*!
 @method passwordDidEndEditing:
 @discussion password編集完了時の通知,値の保存を行う.
 */
- (void) passwordDidEndEditing:(id)sender;



@end
