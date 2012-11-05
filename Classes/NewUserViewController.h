//
//  NewUserViewController.h
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
  UILabel *navigationTitle;
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
 @property navigationTitle
 */
@property (nonatomic, retain) IBOutlet UILabel *navigationTitle;

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
