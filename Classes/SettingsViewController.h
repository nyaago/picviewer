//
//  SettingsViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/05/18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
