//
//  RootViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "NewUserViewController.h"
#import "PicasaFetchController.h"

/*!
 @class RootViewController
 RootのView. ユーザの一覧を表示するView
 */
@interface RootViewController : UITableViewController 
<NSFetchedResultsControllerDelegate,NewUserViewControllerDeleate, PicasaFetchControllerDelegate> {
  NSFetchedResultsController *fetchedUsersController;
  
  NSManagedObjectContext *managedObjectContext;
  
  UIBarButtonItem *addButton;
  
}

/*!
 @prooerty fetchedUsersController
 @discussion User一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedUsersController;
/*!
 @prooerty NSManagedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;



@end
