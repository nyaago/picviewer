//
//  AlbumTableViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "PicasaFetchController.h"
#import "QueuedURLDownloader.h"

/*!
 @class AlbumTableViewController
 @discussion アルバム一覧のView
 */
@interface AlbumTableViewController : UITableViewController 
<NSFetchedResultsControllerDelegate, PicasaFetchControllerDelegate, 
QueuedURLDownloaderDelegate> {
  
  NSFetchedResultsController *fetchedAlbumsController;
  NSManagedObjectContext *managedObjectContext;
  User *user;
  QueuedURLDownloader *downloader;
  UIBarButtonItem *backButton;
  BOOL hasErrorInDownloading;
  BOOL hasErrorInInsertingThumbnail;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;

}

/*!
 @property fetchedAlbumsController
 @discussion Album一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedAlbumsController;

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*!
 @property user
 @discussion 現在選択されているUser
 */
@property (nonatomic, retain) User *user;

/*!
 @method backAction:
 Back Action
 */
- (void) backAction:(id)sender;

/*!
 @method backButton
 @discussion 戻るボタン返す
 */
- (UIBarButtonItem *)backButton;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

@end
