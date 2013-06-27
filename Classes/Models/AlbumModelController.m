//
//  AlbumModelController.m
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


- (NSFetchedResultsController *)createFetchedAlbumsController;

@end


@implementation AlbumModelController

@synthesize user;
@synthesize fetchedAlbumsController;

- (id)init {
	self = [super init];
  if(self) {
  }
  return self;
}

- (id) initWithContext:(NSManagedObjectContext *)context withUser:(User *)userObj {
  self = [super initWithContext:context];
  if(self) {
    user = [userObj retain];
  }
  return self;
}

- (void) dealloc {
  if(user)
    [user release];
  if(fetchedAlbumsController) 
    [fetchedAlbumsController release];
  [super dealloc];
}

- (NSFetchedResultsController *)fetchedAlbumsController {
  
  if (fetchedAlbumsController != nil) {
    return fetchedAlbumsController;
  }
  [self performSelectorOnMainThread:@selector(createFetchedAlbumsController)
                         withObject:nil
                      waitUntilDone:YES];
  NSError *error;
  [fetchedAlbumsController performFetch:&error];
  return fetchedAlbumsController;
}

- (void) clearFetchAlbumsController {
  if(fetchedAlbumsController) {
    [fetchedAlbumsController release];
    fetchedAlbumsController = nil;
  }
}

- (Album *)insertAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject{
  
  // 新しい永続化オブジェクトを作って
  NSManagedObject *newManagedObject 
  = [self insertNewObjectForEntityForName:@"Album"];
  
  // 値を設定
  [newManagedObject setValue:[album GPhotoID] forKey:@"albumId"];
  [self fillAlbumObject:(Album *)newManagedObject 
         withGDataEntry:album 
               withUser:userObject];
  
  
  // Save the context.
  if ([self.user respondsToSelector:@selector(addAlbumObject:) ] ) {
    [self.user addAlbumObject:newManagedObject];
  }
  
  NSError *error = [self save];
  if (error) {
    //
    NSLog(@"Unresolved error %@", error);
    return nil;
  }
  [self clearFetchAlbumsController];
  return (Album *)newManagedObject;
}

- (Album *)updateAlbum:(Album *)albumObject 
        withGDataAlbum:(GDataEntryPhotoAlbum *)album   withUser:(User *)userObject {
  
  // 値を設定
  [self fillAlbumObject:albumObject 
         withGDataEntry:album 
               withUser:userObject];
  
  // Save the context.
  NSError *error = [self save];
  if (error) {
    //
    NSLog(@"Unresolved error %@", error);
    return nil;
  }
  [self clearFetchAlbumsController];
  return albumObject;
}

- (Album *)fillAlbumObject:(Album *)albumObject
            withGDataEntry:(GDataEntryPhotoAlbum *)album 
                  withUser:(User *)userObject {
  // 各値を設定（If appropriate, configure the new managed object.）
  [albumObject setValue:[[album title] contentStringValue] forKey:@"title"];
  /*
  NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
  [formatter setDateStyle:NSDateFormatterFullStyle];
  NSLog(@"album - %@ timestamp = %@",
        [album title],
        [formatter stringFromDate:[[album timestamp] dateValue]]);
	[formatter release];
   */
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
  [self.managedObjectContext performSelector:@selector(deleteObject:)
                                    onThread:[NSThread mainThread]
                                  withObject:albumObject
                               waitUntilDone:YES];

  // Save the context.
  NSError *error = [self save];
  if (error) {
    //
    NSLog(@"Unresolved error %@", error);
  }
  [pool drain];
  [self clearFetchAlbumsController];
  return;
}

- (void)deleteAlbumsWithUserFeed:(GDataFeedPhotoUser *)feed 
                        withUser:(User *)userObject 
                        hasError:(BOOL *)f {
  
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@ ", 
     @"user.userId", userObject.userId ];
  [fetchRequest setPredicate:predicate];
  
  
  NSError *error;
  NSArray *items = [self executeFetchRequest:fetchRequest];
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
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", 
     @"albumId", [album GPhotoID],
     @"user.userId", userObject.userId ];
  [fetchRequest setPredicate:predicate];
  
  NSError *error;
  NSArray *items = [self executeFetchRequest:fetchRequest ];
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
  if ([self save]) {
    // 
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  [self clearFetchAlbumsController];
  return album;
}



-(NSUInteger) albumCount {
  if(!self.fetchedAlbumsController) {
    return 0;
  }
  id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedAlbumsController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
}

-(Album *) albumAt:(NSInteger)index {
  NSUInteger indexes[2];
  if(index >= [self albumCount])
    return nil;
  indexes[0] = 0;
  indexes[1] = index;

  return (Album *)[self.fetchedAlbumsController objectAtIndexPath:[NSIndexPath
                                                                   indexPathWithIndexes:indexes length:2]];
}

- (NSFetchedResultsController *)createFetchedAlbumsController {
  
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Album"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate
  = [NSPredicate predicateWithFormat:@"%K = %@", @"user.userId", user.userId];
  [fetchRequest setPredicate:predicate];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp"
                                                                 ascending:NO];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedAlbumsController = [[NSFetchedResultsController alloc]
                                                          initWithFetchRequest:fetchRequest
                                                          managedObjectContext:self.managedObjectContext
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

/*!
 @metohd setLastMod
 @discussion 最後にアルバムの追加/削除/更新が行われた日時を記録
 */
- (void) setLastMod {
  NSLog(@"setLastAdd");
  self.user.lastModAlbumAt = [NSDate date];
  [self save];
}



@end
