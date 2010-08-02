//
//  AlbumModelController.m
//  PicasaViewer
//
//  Created by nyaago on 10/08/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AlbumModelController.h"

@interface AlbumModelController(Private)

/*!
 @method fillAlbumObject:withGDataEntry:withUser
 @discussion GoogleのPhotoAlbumのEntryよりCoreDataのAlbum Objectへ値を設定
 @param albumObject - 設定対象のAlbum Object
 @param album - GoogleDataのAlbumEntry
 @param withUser - CoreDataのuser Object
 @return CoreDataのAlbumObject
 */
- (Album *)fillAlbumObject:(Album *)albumObject
            withGDataEntry:(GDataEntryPhotoAlbum *)album 
                  withUser:(User *)userObject;




@end


@implementation AlbumModelController

@synthesize user;
@synthesize managedObjectContext;
@synthesize fetchedAlbumsController;

- (id)init {
	self = [super init];
  if(self) {
  }
  return self;
}

- (id) initWithContext:(NSManagedObjectContext *)context withUser:(User *)userObj {
  self = [self init];
  if(self) {
    managedObjectContext = [context retain];
    user = [userObj retain];
  }
  return self;
}

- (void) dealloc {
  if(user)
    [user release];
  if(fetchedAlbumsController) 
    [fetchedAlbumsController release];
  if(managedObjectContext)
    [managedObjectContext release];
  [super dealloc];
}

- (NSFetchedResultsController *)fetchedAlbumsController {
  
  if (fetchedAlbumsController != nil) {
    return fetchedAlbumsController;
  }
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"user.userId", user.userId];
  [fetchRequest setPredicate:predicate];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" 
                                                                 ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedAlbumsController = [[NSFetchedResultsController alloc] 
                                                          initWithFetchRequest:fetchRequest 
                                                          managedObjectContext:managedObjectContext 
                                                          sectionNameKeyPath:nil 
                                                          cacheName:@"Root"];
  aFetchedAlbumsController.delegate = self;
  self.fetchedAlbumsController = aFetchedAlbumsController;
  
  [aFetchedAlbumsController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  
  return fetchedAlbumsController;
}    

- (Album *)insertAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject{
  
  // 新しい永続化オブジェクトを作って
  NSManagedObject *newManagedObject 
  = [NSEntityDescription insertNewObjectForEntityForName:@"Album"
                                  inManagedObjectContext:managedObjectContext];
  
  // 値を設定
  [newManagedObject setValue:[album GPhotoID] forKey:@"albumId"];
  [self fillAlbumObject:(Album *)newManagedObject 
         withGDataEntry:album 
               withUser:userObject];
  
  
  // Save the context.
  NSError *error = nil;
  if ([self.user respondsToSelector:@selector(addAlbumObject:) ] ) {
    [self.user addAlbumObject:newManagedObject];
  }	
  if (![managedObjectContext save:&error]) {
    // 
    return nil;	
  }
  return (Album *)newManagedObject;
}

- (Album *)updateAlbum:(Album *)albumObject 
        withGDataAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject {
  
  // 値を設定
  [self fillAlbumObject:albumObject 
         withGDataEntry:album 
               withUser:userObject];
  
  // Save the context.
  NSError *error = nil;
  if (![managedObjectContext save:&error]) {
    // 
    return nil;	
  }
  return albumObject;
}

- (Album *)fillAlbumObject:(Album *)albumObject
            withGDataEntry:(GDataEntryPhotoAlbum *)album 
                  withUser:(User *)userObject {
  // 各値を設定（If appropriate, configure the new managed object.）
  [albumObject setValue:[[album title] contentStringValue] forKey:@"title"];
  [albumObject setValue:[[album timestamp] dateValue] forKey:@"timeStamp"];
  if([album description]) {
		[albumObject setValue:[album description] forKey:@"descript"];
  }
	[albumObject setValue:[album access] forKey:@"access"];
  [albumObject setValue:[album photosUsed] forKey:@"photosUsed"];
  
  // thumbnailのurl
  if([[[album mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[album mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    [albumObject setValue:[thumbnail URLString] forKey:@"urlForThumbnail"];
  }
  return albumObject;
}


- (void)deleteAlbum:(Album *)albumObject withUser:(User *)userObject {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSSet *set = [NSSet setWithObject:albumObject];
  // 参照元User削除
  [userObject removeAlbum:set];
  // Album削除
  [managedObjectContext deleteObject:(NSManagedObject *)albumObject];
  // Save the context.
  NSError *error = nil;
  if (![managedObjectContext save:&error]) {
    NSLog(@"error Occured in remveing Album - %@", error);
    [pool drain];
    return;
  }
  [pool drain];
  return;
}

- (void)deleteAlbumsWithUserFeed:(GDataFeedPhotoUser *)feed 
                        withUser:(User *)userObject 
                        hasError:(BOOL *)f {
  
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@ ", 
     @"user.userId", userObject.userId ];
  [fetchRequest setPredicate:predicate];
  
  
  NSError *error;
  NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
  if(!items) {
    NSLog(@"Unresolved error %@", error);
    *f = YES;
    return;
  }
  
  
  NSArray *entries = [feed entries];
	
  for(Album *albumObject in items) {
    BOOL found = NO;
    for(GDataEntryPhotoAlbum *albumEntry in entries) {
      NSLog(@"compare %@ with %@", albumObject.albumId, [albumEntry GPhotoID]);
      if ([albumObject.albumId isEqualToString:[albumEntry GPhotoID]]) {
        found = YES;
      }
    }
    if(found == NO) {
	    [self deleteAlbum:albumObject withUser:userObject];
    }
  }
}

- (Album *)selectAlbum:(GDataEntryPhotoAlbum *)album   
              withUser:(User *)userObject  hasError:(BOOL *)f{
  *f = NO;
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", 
     @"albumId", [album GPhotoID],
     @"user.userId", userObject.userId ];
  [fetchRequest setPredicate:predicate];
  
  NSError *error;
  NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
  if(!items) {
    NSLog(@"Unresolved error %@", error);
    *f = YES;
    return nil;
  }
  if([items count] >= 1) {
    return (Album *)[items objectAtIndex:0];
  }
  
  return nil;
}

- (Album *)updateThumbnail:(NSData *)thumbnailData forAlbum:(Album *)album {
  if(!album)
    return nil;
  album.thumbnail = thumbnailData;
  NSError *error = nil;
  if (![managedObjectContext save:&error]) {
    // 
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  return album;
}



-(NSUInteger) albumCount {
  if(!fetchedAlbumsController) {
    return 0;
  }
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedAlbumsController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
}

-(Album *) albumAt:(NSIndexPath *)indexPath {
  return (Album *)[fetchedAlbumsController objectAtIndexPath:indexPath];
}


@end
