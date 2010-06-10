//
//  PhotoActionDelegate.m
//  PicasaViewer
//
//  Created by nyaago on 10/06/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotoActionDelegate.h"

@interface PhotoActionDelegate (Private)

/*!
 @method sendPhotoByEMail
 @discussion メイルの送信.
 MailComposeViewを表示して写真をメイルを送信する。
 */
-(void) sendPhotoByEMail;

/*!
 @method savePhotoToAlbum
 @discussion PhotoLibraryへの写真の保存
 */
-(void) savePhotoToAlbum;
	
/*
 @method didSavedPhotoToAlubum:didFinishSavingWithError:contextInfo
 @discussion 写真保存完了時の通知イベント.
 エラーであれば、Alertを表示.
 */
- (void) didSavedPhotoToAlbum: (UIImage *) image
      didFinishSavingWithError: (NSError *) error
                   contextInfo: (void *) contextInfo;

@end

@implementation PhotoActionDelegate

- (id) initWithPhotoObject:(Photo *)photoObject 
	withParentViewController:(UIViewController *)viewController {
  self = [super init];
  if(self) {
    photo = photoObject;
    parentViewController = viewController;
    
    [photo retain];
    [parentViewController retain];
  }
  return self;
}

- (void)dealloc {
  [photo release];
  [parentViewController release];
  [super dealloc];
}

#pragma mark Private

-(void) sendPhotoByEMail {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  MFMailComposeViewController *composeViewController  =
  		[[MFMailComposeViewController alloc] init];
  [composeViewController setMessageBody:@"" isHTML:NO];
  [composeViewController setSubject:photo.title];    
  PhotoImage *photoImage = (PhotoImage *)photo.photoImage;
  [composeViewController addAttachmentData:photoImage.image
                                  mimeType:@"image/jpg" 
                                  fileName:photo.title ];
  composeViewController.mailComposeDelegate = self;
  [parentViewController presentModalViewController:composeViewController 
                                        animated:YES];
  [pool drain];
}

- (void)savePhotoToAlbum {
  PhotoImage *photoImage = (PhotoImage *)photo.photoImage;
  UIImage *image = [[UIImage alloc] initWithData:photoImage.image];
  UIImageWriteToSavedPhotosAlbum(image, 
                                 self, 
                                 @selector(didSavedPhotoToAlbum:didFinishSavingWithError:contextInfo:), 
                                 nil);
}

- (void) didSavedPhotoToAlbum: (UIImage *) image
      didFinishSavingWithError: (NSError *) error
                   contextInfo: (void *) contextInfo {
  NSLog(@"didSavedPhotoToAlubum ");
  if(error) {
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"ERROR", @"error") 
                              message:NSLocalizedString(@"Error.SaveToLibrary",
                                                        "error in saving") 
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Ok")
                              otherButtonTitles:nil ];
    [alertView show];
    [alertView release];
  }
}


#pragma mark UIActionSheetDelegate

/*!
 
 */
- (void)actionSheet:(UIActionSheet *)actionSheet 
clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  NSLog(@"action sheet - selected index = %d", buttonIndex);
  //  UIViewController *contoller ;
  switch (buttonIndex) {
    case 0:	  // メイル送信
      [self sendPhotoByEMail];
      break;
    case 1:	  // アルバムに保存
      [self savePhotoToAlbum];
      break;
    default:
      NSLog(@"canceled .");
      break;
  }
  
}

#pragma mark -

   
#pragma mark MFMailComposeViewControllerDelegate
   
/*!
 @method mailComposeController:didFinishWithResult:error
 @discussion メイル送信後の通知
 エラー時のメッセージ表示、リソースの解放を行う。
 */
 - (void)mailComposeController:(MFMailComposeViewController*)controller 
                     didFinishWithResult:(MFMailComposeResult)result 
                                   error:(NSError*)error {

  UIAlertView *alertView = nil;
  if(error) {
   	alertView = [[UIAlertView alloc] 
                initWithTitle:NSLocalizedString(@"ERROR", @"error") 
                message:NSLocalizedString(@"Error.EMail","error!") 
                delegate:nil
                cancelButtonTitle:NSLocalizedString(@"OK", @"Ok")
                otherButtonTitles:nil ];
  }
  else {
  }
  [parentViewController dismissModalViewControllerAnimated:YES];
  [controller release];
  // [self release];
  if(alertView) {
   	[alertView show];
   	[alertView release];
 	}
}
   
#pragma mark -
   
@end
