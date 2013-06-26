//
//  TextViewController.h
//  PicasaViewer
//
//  Created by nyaago on 2013/06/25.
//
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>

@class TextViewController;

/*!
 @protocol TextViewControllerDelegate
 @discussion テキスト入力のView controllerのdelegate
 */
@protocol TextViewControllerDelegate <NSObject>

/*!
 @method textViewControler:input:
 @discussion テキスト入力完了時のdelegate
 @param controller
 @param s 変更確定したテキスト
 */
- (void) textViewControler:(TextViewController *)controller input:(NSString *)s;

@end

/*!
 @class TextViewController
 @discussion テキスト入力のView controller
 */
@interface TextViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, assign)  NSObject <TextViewControllerDelegate> *delegate;
@property (nonatomic, readonly) UITextView *textView;
@property (nonatomic, readonly) UIBarButtonItem *backButton;

/*!
 @property maxLength
 @discussion 入力文字数の最大
 */
@property (nonatomic, assign) NSInteger maxLength;
/*!
 @property isMustiLine
 @discussion 複数行を入力可とするか/不可か (YES/NO）
 */
@property (nonatomic, assign) BOOL isMustiLine;
/*!
 @property keybordType
 @discussion キーボードタイプ
 */
@property (nonatomic, assign) UIKeyboardType keybordType;
/*!
 @property tag
 @discussioin タグ番号
 */
@property (nonatomic, assign) NSInteger tag;
/*!
 @property text
 @discussion 編集テキスト
 */
@property (nonatomic, strong) NSString *text;

@end
