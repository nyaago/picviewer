//
//  PhotoActionDelegate.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "Photo.h"
#import "PhotoImage.h"

/*!
 @class PhotoActionDelegate
 @discussion 写真Viewからのアクションシートでの選択時のアクションのDelegateの実装
 */
@interface PhotoActionDelegate  : NSObject 
<UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	Photo *photo;
  UIViewController *parentViewController;
}

/*!
 @method initWithPhotoObject:
 @discussion 対象のPhoto Objectを指定しての初期化
 */
- (id) initWithPhotoObject:(Photo *)photoObject 
withParentViewController:(UIViewController *)viewController;

@end
