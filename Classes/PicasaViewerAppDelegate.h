//
//  PicasaViewerAppDelegate.h
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
  UINavigationController *detailNavigationController;
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
/*!
 @property detailNavigationController
 */
@property (nonatomic, retain, readonly) IBOutlet UINavigationController *detailNavigationController;

- (NSString *)applicationDocumentsDirectory;

/*!
 @property photoListViewContriller
 */
@property (nonatomic,retain) PhotoListViewController *photoListViewController;


- (void) onSelectUser:(User *)user;

@end


