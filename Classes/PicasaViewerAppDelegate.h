//
//  PicasaViewerAppDelegate.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

/*!
 @class PicasaViewerAppDelegate
 ApplicationのDelegate
 */
#import "PhotoListViewController.h"
@interface PicasaViewerAppDelegate : NSObject <UIApplicationDelegate> {
  
  NSManagedObjectModel *managedObjectModel;
  NSManagedObjectContext *managedObjectContext;	    
  NSPersistentStoreCoordinator *persistentStoreCoordinator;
  
  UIWindow *window;
  UINavigationController *navigationController;
  PhotoListViewController *photoListViewController;
  
}

/*!
 @property managedObjectModel
 @discussion CoreDataのObectModel(Entity,Relationの定義）
 */
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;

/*!
 @property managedObjectModel
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
/*!
 @property persistentStoreCoordinator
 @discussion 永続化のStoreへのインターフェイス。SQLiteデータベースをStoreとする。
 */
@property (nonatomic, retain, readonly) 
										NSPersistentStoreCoordinator *persistentStoreCoordinator;

/*!
 @property window
 */
@property (nonatomic, retain) IBOutlet UIWindow *window;
/*!
 @property navigationController
 */
@property (nonatomic, retain, readonly) IBOutlet UINavigationController *navigationController;

- (NSString *)applicationDocumentsDirectory;

/*!
 @property photoListViewContriller
 */
@property (nonatomic,retain, readonly) PhotoListViewController *photoListViewController;


@end


