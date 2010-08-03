//
//  PhotoModelController.m
//  PicasaViewer
//
//  Created by nyaago on 10/08/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotoModelController.h"
#import "Photo.h"
#import "Album.h"

@implementation PhotoModelController

@synthesize album;
@synthesize managedObjectContext;
@synthesize fetchedPhotosController;


- (id)init {
	self = [super init];
  if(self) {
    lockSave = [[NSLock alloc] init];
  }
  return self;
}

- (id) initWithContext:(NSManagedObjectContext *)context withAlbum:(Album *)albumObj {
  self = [self init];
  if(self) {
    managedObjectContext = [context retain];
    album = [albumObj retain];
  }
  return self;
}


- (void) dealloc {
  [lockSave release];
  if(album)
    [album release];
  if(fetchedPhotosController)
    [fetchedPhotosController release];
  if(managedObjectContext) 
    [managedObjectContext release];
  [super dealloc];
}

- (Photo *)insertPhoto:(GDataEntryPhoto *)photo   withAlbum:(Album *)album {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *photoId = [photo GPhotoID];
  // 新しい永続化オブジェクトを作って
  Photo *photoObject 
  = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                           inManagedObjectContext:managedObjectContext];
  // 値を設定
  [photoObject setValue:photoId forKey:@"photoId"];
  [photoObject setValue:[[photo title] contentStringValue] forKey:@"title"];
  [photoObject setValue:[[photo timestamp] dateValue] forKey:@"timeStamp"];
  if([photo geoLocation]) {
	  [photoObject setValue:[[photo geoLocation] coordinateString] forKey:@"location"];
  }
  if([photo description] ) {
		[photoObject setValue:[photo description] forKey:@"descript"];
  }
  if([photo width] ) {
    [photoObject setValue:[photo width] forKey:@"width"];
  }
  if([photo height] ) {
    [photoObject setValue:[photo height] forKey:@"height"];
  }
  
  // 画像url
  if([[[photo mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[photo mediaGroup] mediaThumbnails]  
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    [photoObject setValue:[thumbnail URLString] forKey:@"urlForThumbnail"];
  }
  if([[[photo mediaGroup] mediaContents] count] > 0) {
    GDataMediaContent *content = [[[photo mediaGroup] mediaContents]  
                                  objectAtIndex:0];
    NSLog(@"URL for the photo - %@", [content URLString] );
    [photoObject setValue:[content URLString] forKey:@"urlForContent"];
  }
  
  // Save the context.
  NSError *error = nil;
  if ([self.album respondsToSelector:@selector(addPhotoObject:) ] ) {
    [self.album addPhotoObject:(NSManagedObject *)photoObject];
  }	
  [lockSave lock];
  if (![managedObjectContext save:&error]) {
    // 
    [lockSave unlock];
    NSLog(@"Unresolved error %@", error);
    NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
		NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
		if(detailedErrors != nil && [detailedErrors count] > 0) {
			for(NSError* detailedError in detailedErrors) {
				NSLog(@"  DetailedError: %@", [detailedError userInfo]);
			}
		}
		else {
			NSLog(@"  %@", [error userInfo]);
		}
    
    [pool drain];
    return nil;	
  }
  //  [managedObjectContext processPendingChanges]:
  [lockSave unlock];
  [pool drain];
  return photoObject;
}


- (Photo *)updateThumbnail:(NSData *)thumbnailData forPhoto:(Photo *)photo {
  if(!photo)
    return nil;
  if(!thumbnailData || [thumbnailData length] == 0) 
    return photo;
  photo.thumbnail = thumbnailData;
  NSError *error = nil;
  [lockSave lock];
  if (![managedObjectContext save:&error]) {
    // 
    [lockSave unlock];
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  [lockSave unlock];
  return photo;
}

- (void)removePhotos {
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
  [fetchRequest setPredicate:predicate];
  
  NSError *error;
  // データの削除、親(album)からの関連の削除 + (albumに含まれる)全Photoデータの削除
  NSArray *items = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	NSSet *set = [NSSet setWithArray:items];
  [album removePhoto:set];
  for (NSManagedObject *managedObject in items) {
    [managedObjectContext deleteObject:managedObject];
    NSLog(@" object deleted");
  }
  //
  if (![managedObjectContext save:&error]) {
    NSLog(@"Error deleting- error:%@",error);
  }
  [fetchRequest release];
	//[items release];  
  return;
}    

- (NSFetchedResultsController *)fetchedPhotosController {
  
  if (fetchedPhotosController != nil) {
    return fetchedPhotosController;
  }
  [NSFetchedResultsController deleteCacheWithName:nil];
  
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
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
  NSFetchedResultsController *aFetchedPhotosController = [[NSFetchedResultsController alloc] 
                                                          initWithFetchRequest:fetchRequest 
                                                          managedObjectContext:managedObjectContext 
                                                          sectionNameKeyPath:nil 
                                                          cacheName:@"Root"];
  aFetchedPhotosController.delegate = self;
  self.fetchedPhotosController = aFetchedPhotosController;
  
  [aFetchedPhotosController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  
  return fetchedPhotosController;
}    


- (Photo *)photoAt:(NSUInteger)index {
  NSUInteger indexes[2];
  if(index >= [self photoCount])
    return nil;
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  
  return photoObject;
  
}

- (NSUInteger)photoCount {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
  
}


@end