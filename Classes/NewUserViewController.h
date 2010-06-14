//
//  NewUserViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NewUserViewControllerDeleate

- (BOOL) doneWithNewUser:(NSString *)user;

@end


/*!
 @class NewUserViewController
 ユーザを追加するView
 */
@interface NewUserViewController : UIViewController {
  UIBarButtonItem *doneButton;
  UIBarButtonItem *cancelButton;
  UITextField *userField;
  UILabel *captionLabel;
  UILabel *explanationLabel;
  NSObject <NewUserViewControllerDeleate> *delegate;
}

/*!
 @property doneButton
 */
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
/*!
 @property cancelButton
 */
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
/*!
 */
@property (nonatomic, retain) IBOutlet UITextField *userField;

/*!
 @property captionLabel
 @discussion アカウント名入力のキャプションとなるラベル
 */
@property (nonatomic, retain) IBOutlet UILabel *captionLabel;

/*!
 @property explanationLabel
 @discussion 説明文のラベル
 */
@property (nonatomic, retain) IBOutlet UILabel *explanationLabel;



/*!
 @property delegate
 */
@property (nonatomic, retain) NSObject <NewUserViewControllerDeleate> *delegate;



/*!
 @method doneAction
 @discussion Doneボタンのアクション.入力されたユーザの追加を行い、Viewを破棄する。
 */
- (void)doneAction:(id)sender;
/*!
 @method cancelAction
 @discussion Cancelボタンのアクション.Viewを破棄する。
 */
- (void)cancelAction:(id)sender;

@end
