//
//  PicasaViewerAppDelegate.m
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

#import "PicasaViewerAppDelegate.h"
#import "RootViewController.h"
#import "PhotoListViewController.h"

@interface PicasaViewerAppDelegate(Private)

/*!
 @method createNavigationController
 @discussion topの(iPadの場合は、splitViewの詳細Viewの)
 Nagation view controller を生成
 */
- (UINavigationController *) createNavigationController;

@end

@implementation PicasaViewerAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize photoListViewController;

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
  
  // Override point for customization after app launch    
  // xibを使わない..
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds] ];
  window.backgroundColor = UIColor.blackColor;
  //
  //CGRect bounds = [[UIScreen mainScreen] bounds];
  /*
  NSLog(@"window - x => %f,y => %f, width => %f, height => %f", 
        bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
   */
  
                                     
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // iPadの場合-SplitViewを表示
    photoListViewController = [[PhotoListViewController alloc]
                               initWithNibName:@"PhotoListViewController-iPad"
                                        bundle:nil];

    UINavigationController *detailNav = [[[UINavigationController alloc]
                                         initWithRootViewController:photoListViewController]
                                         autorelease];
    NSArray *controllers = [NSArray arrayWithObjects:[self createNavigationController],
                            detailNav,
                            nil];
    UISplitViewController *splitController = [[[UISplitViewController alloc] init] autorelease];
    [splitController setDelegate:photoListViewController];
    [splitController setViewControllers:controllers];
    [window setRootViewController:splitController];
  }
  else {
    // iPhone
    [window setRootViewController:[self createNavigationController]];
  }
  
  [window makeKeyAndVisible];
}

/**
 applicationWillTerminate: saves changes in the application's managed object context 
 before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
  NSLog(@"applicationWillTerminate:");
  NSError *error = nil;
  if (managedObjectContext != nil) {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. 
       You should not use this function in a shipping application, 
       although it may be useful during development. 
       If it is not possible to recover from the error, 
       display an alert panel that instructs the user to quit the application
       by pressing the Home button.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    } 
  }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, 
 it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
  
  if (managedObjectContext != nil) {
    return managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, 
 it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
  
  if (managedObjectModel != nil) {
    return managedObjectModel;
  }
  managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
  return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, 
 it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  
  if (persistentStoreCoordinator != nil) {
    return persistentStoreCoordinator;
  }
  
  NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] 
                                             stringByAppendingPathComponent: @"PicasaViewer.sqlite"]];
  
  NSError *error = nil;
  NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                           [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                initWithManagedObjectModel:[self managedObjectModel]];
  if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                configuration:nil 
                                                          URL:storeUrl 
                                                      options:options 
                                                        error:&error]) {
    /*
     Replace this implementation with code to handle the error appropriately.
     
     abort() causes the application to generate a crash log and terminate. 
     You should not use this function in a shipping application, 
     although it may be useful during development. 
     If it is not possible to recover from the error, 
     display an alert panel that instructs the user 
     to quit the application by pressing the Home button.
     
     Typical reasons for an error here include:
     * The persistent store is not accessible
     * The schema for the persistent store is incompatible 
     with current managed object model
     Check the error message to determine what the actual problem was.
     */
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }    
  
  return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark UI

- (UINavigationController *) createNavigationController {
  
  if(navigationController == nil) {
    RootViewController *rootViewController = [[[RootViewController alloc] init] autorelease];
    
    navigationController = [[UINavigationController alloc]
                            initWithRootViewController:rootViewController];
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationController.toolbar.barStyle = UIBarStyleBlack;
    navigationController.toolbar.translucent = YES;
    rootViewController.navigationController.navigationBarHidden = NO;
    rootViewController.navigationController.toolbarHidden = NO;
    rootViewController.managedObjectContext = self.managedObjectContext;
  }
  return navigationController;
}


#pragma mark -
#pragma mark Application's Documents directory
/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
  return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                              NSUserDomainMask, YES) 
          lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
  [managedObjectContext release];
  [managedObjectModel release];
  [persistentStoreCoordinator release];
  
  [navigationController release];
  [photoListViewController release];
  [window release];
  [super dealloc];
}


@end

/*!
 @class UINavigationController
 @discussion 機器回転（Rotation）のための子へのDelegationを行うためのカテゴリーを実装
 */
@implementation UINavigationController (Rotation)



/*!
 子のviewController の定義にdelegateさせる
 */
- (NSUInteger)supportedInterfaceOrientations{
  
  return [self.viewControllers.lastObject supportedInterfaceOrientations];
  
}


/*!
 子のviewController の定義にdelegateさせる
*/
- (BOOL)shouldAutorotate{
  
  return [self.viewControllers.lastObject shouldAutorotate];
  
}


/*!
 子のviewController の定義にdelegateさせる
 */
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
  
  return [self.viewControllers.lastObject preferredInterfaceOrientationForPresentation];
  
}


@end
