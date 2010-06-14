//
//  PhotoViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"
#import "QueuedURLDownloader.h"
#import "DeviceRotation.h"
#import "PageControlViewController.h"

/*!
 @class PhotoViewController
 @discussion 写真表示View
 */
@interface PhotoViewController : UIViewController 
<UIScrollViewDelegate, DeviceRotationDelegate,QueuedURLDownloaderDelegate,
ScrolledPageViewDelegate> {
  NSFetchedResultsController *fetchedPhotosController;
  NSManagedObjectContext *managedObjectContext;
  
  UIBarButtonItem *prevButton;
  UIBarButtonItem *nextButton;
  UIScrollView    *scrollView;
  UIImageView	  *imageView;
  UIToolbar		  *toolbar;
  UIBarButtonItem *backButton;
  
  // 表示する写真のfetchedPhotosController上のインデックス番号
  NSUInteger  indexForPhoto;
  // Downloader
  QueuedURLDownloader *downloader;
  
  // PageをControll するViewのController
  PageControlViewController *pageController;
  
  // 
  NSInteger lastTapCount;
}

/*!
 @property fetchedAlbumsController
 @discussion Album一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedPhotosController;

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*!
 @property prevButton
 @discussion 前の写真を表示するためのボタン
 */
@property (nonatomic,retain) IBOutlet UIBarButtonItem *prevButton;
/*!
 @property nextButton
 @discussion 次の写真を表示するためのボタン
 */
@property (nonatomic,retain) IBOutlet UIBarButtonItem *nextButton;

/*!
 @property scrollView
 @discussion 写真をScrollするためのView(ImageViewの親)
 */
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

/*!
 @property pageController
 @discussion PageをControll するViewのController
 */
@property (nonatomic, retain) PageControlViewController *pageController;


/*!
 @property imageView
 */
@property (nonatomic, retain) UIImageView *imageView;

/*!
 @property toolbar
 @discussion 
 */
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;


/*!
 @property indexForPhoto
 @discussion 表示する写真のfetchedPhotosController上のインデックス番号
 */
@property (nonatomic) NSUInteger indexForPhoto;


/*!
 @method photoAt:
 @discussion 指定したIndexのPhotoObjectを返す
 @param index 0起点のindex
 @return Photo Object
 */
- (Photo *)photoAt:(NSUInteger)index;

/*!
 @method thumbnailAt:
 @discussion 指定したIndexのthumbnail画像のUIImageViewを返す
 @param index 0起点のindex
 @return UIImageView
 */
- (UIImageView *)thumbnailAt:(NSUInteger)index;


/*!
 @method photoImageAt:
 @discussion 指定したIndexの画像のUIImageViewを返す
 @param index 0起点のindex
 @return UIImageView 写真がなければ nil
 */
- (UIImageView *)photoImageAt:(NSUInteger)index;

/*!
 @method photoCount
 @discussion Albumに含まれる写真数を返す
 */
- (NSUInteger)photoCount;

/*!
 @method setIndexForPhoto
 @discussion インデックスを指定して写真を表示する.
 @param index 表示する写真のfetchedPhotosController上のインデックス番号
 */
- (void) setIndexForPhoto:(NSUInteger)index;

/*!
 @method backButton
 @discussion 戻るボタンを返す
 */
+ (UIBarButtonItem *)backButton;

@end
