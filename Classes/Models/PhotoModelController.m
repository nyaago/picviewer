//
//  PhotoModelController.m
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

#import "PhotoModelController.h"
#import "Photo.h"
#import "Album.h"

@interface PhotoModelController(private)

- (NSFetchedResultsController *)createFetchedPhotosController;

@end


@implementation PhotoModelController

@synthesize album;
//@synthesize fetchedPhotosController;


- (id)init {
	self = [super init];
  if(self) {
    lockSave = [[NSLock alloc] init];
  }
  return self;
}

- (id) initWithContext:(NSManagedObjectContext *)context {
  self = [super initWithContext:context];
  if(self) {
  }
  return self;
}


- (void) dealloc {
  [lockSave release];
  if(album)
    [album release];
  if(fetchedPhotosController)
    [fetchedPhotosController release];
  [super dealloc];
}

- (void) setAlbum:(Album *)newAlbum {
//  if(album != newAlbum) {
    [album release];
    album = newAlbum;
    [album retain];
    if(fetchedPhotosController) {
      [fetchedPhotosController release];
      fetchedPhotosController = nil;
    }
 // }
}

- (Photo *)insertPhoto:(GDataEntryPhoto *)photo   withAlbum:(Album *)album {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // 新しい永続化オブジェクトを作って
  Photo *photoObject 
  = (Photo *)[self insertNewObjectForEntityForName:@"Photo"];
  // 値を設定
  [self gDataEntryPhoto:photo toPhotoModel:photoObject];
  
  // Save the context.
  if ([self.album respondsToSelector:@selector(addPhotoObject:) ] ) {
    [self.album addPhotoObject:(NSManagedObject *)photoObject];
  }
  NSError *error = [self save];
  if (error) {
    // 
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
  [pool drain];
  [self clearFetchPhotosController];
  return photoObject;
}

- (Photo *)updatePhoto:(Photo *)photoModel fromGDataEntryPhoto:(GDataEntryPhoto *)entry {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  [self gDataEntryPhoto:entry toPhotoModel:photoModel];
  NSError *error = [self save];
  if (error) {
    //
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
  [pool drain];
  [self clearFetchPhotosController];
  return photoModel;
}

- (void) gDataEntryPhoto:(GDataEntryPhoto *)entry toPhotoModel:(Photo *)photoModel {
  [photoModel setValue:[entry GPhotoID] forKey:@"photoId"];
  [photoModel setValue:[[entry title] contentStringValue] forKey:@"title"];
  [photoModel setValue:[[entry timestamp] dateValue] forKey:@"timeStamp"];
  if([entry geoLocation]) {
	  [photoModel setValue:[[entry geoLocation] coordinateString] forKey:@"location"];
  }
  if([entry description] ) {
		[photoModel setValue:[[entry mediaGroup] mediaDescription].contentStringValue
                  forKey:@"descript"];
  }
  if([entry width] ) {
    [photoModel setValue:[entry width] forKey:@"width"];
  }
  if([entry height] ) {
    [photoModel setValue:[entry height] forKey:@"height"];
  }
  
  // 画像url
  if([[[entry mediaGroup] mediaThumbnails] count] > 0) {
    GDataMediaThumbnail *thumbnail = [[[entry mediaGroup] mediaThumbnails]
                                      objectAtIndex:0];
    NSLog(@"URL for the thumb - %@", [thumbnail URLString] );
    [photoModel setValue:[thumbnail URLString] forKey:@"urlForThumbnail"];
  }
  if([[[entry mediaGroup] mediaContents] count] > 0) {
    GDataMediaContent *content = [[[entry mediaGroup] mediaContents]
                                  objectAtIndex:0];
    NSLog(@"URL for the photo - %@", [content URLString] );
    [photoModel setValue:[content URLString] forKey:@"urlForContent"];
  }
  
}

- (Photo *)updateThumbnail:(NSData *)thumbnailData forPhoto:(Photo *)photo {
  if(!photo)
    return nil;
  if(!thumbnailData || [thumbnailData length] == 0) 
    return photo;
  photo.thumbnail = thumbnailData;
  NSError *error = [self save];
  if (error) {
    // 
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  [self clearFetchPhotosController];
  return photo;
}

- (void)removePhoto:(Photo *)photo {
  [NSFetchedResultsController deleteCacheWithName:@"Photo"];
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate
  = [NSPredicate predicateWithFormat:@"%K = %@", @"photoId", photo.photoId];
  [fetchRequest setPredicate:predicate];
  
  // データの削除、
  NSArray *items = [self executeFetchRequest:fetchRequest];
	NSSet *set = [NSSet setWithArray:items];
  [album removePhoto:set];
  for (NSManagedObject *managedObject in items) {
    [self.managedObjectContext performSelector:@selector(deleteObject:)
                                      onThread:[NSThread mainThread]
                                    withObject:managedObject
                                 waitUntilDone:YES];
    
    //    [managedObjectContext deleteObject:managedObject];
    NSLog(@" object deleted");
  }
  //
  /*
  error = [self save];
  if (error) {
    NSLog(@"Error deleting- error:%@",error);
  }
   */
  [fetchRequest release];
  [self clearFetchPhotosController];
  return;

}

- (void)removePhotos {
  [NSFetchedResultsController deleteCacheWithName:@"Photo"];
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
  [fetchRequest setPredicate:predicate];
  
  // データの削除、親(album)からの関連の削除 + (albumに含まれる)全Photoデータの削除
  NSError *error;
  NSArray *items = [self executeFetchRequest:fetchRequest];
	NSSet *set = [NSSet setWithArray:items];
  [album removePhoto:set];
  for (NSManagedObject *managedObject in items) {
    [self.managedObjectContext performSelector:@selector(deleteObject:)
                                 onThread:[NSThread mainThread]
                               withObject:managedObject
                            waitUntilDone:YES];
    
//    [managedObjectContext deleteObject:managedObject];
    NSLog(@" object deleted");
  }
  //
  error = [self save];
  if (error) {
    NSLog(@"Error deleting- error:%@",error);
  }
  [fetchRequest release];
	//[items release];
  [self clearFetchPhotosController];
  return;
}    

- (NSFetchedResultsController *)fetchedPhotosController {
  
  if (fetchedPhotosController != nil) {
    return fetchedPhotosController;
  }
  [self performSelectorOnMainThread:@selector(createFetchedPhotosController)
                         withObject:nil
                      waitUntilDone:YES];
  return fetchedPhotosController;
}    


- (void) clearFetchPhotosController {
  [fetchedPhotosController release];
  fetchedPhotosController = nil;
}

- (Photo *)photoAt:(NSUInteger)index {
  NSUInteger indexes[2];
  if(index >= [self photoCount])
    return nil;
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [ [self fetchedPhotosController]
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  
  return photoObject;
  
}

- (NSUInteger)photoCount {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedPhotosController] sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
  
}

- (NSInteger) indexForPhoto:(Photo *)photo {
  NSUInteger indexes[2];
  indexes[0] = 0;
  for(int i = 0; i < [self photoCount]; ++i) {
    Photo *curPhoto = [self photoAt:i];
    if([curPhoto.photoId isEqual:photo.photoId]) {
      return i;
    }
  }
  return NSNotFound;
  
  NSIndexPath *indexPath = [[self fetchedPhotosController] indexPathForObject:photo ];
  if(indexPath && indexPath.length == 2) {
    return [indexPath indexAtPosition:1];
  }
  return NSNotFound;
}

- (Photo *)selectPhoto:(GDataEntryPhoto *)photo  hasError:(BOOL *)f{
  *f = NO;
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate *predicate 
  = [NSPredicate predicateWithFormat:@"%K = %@ ", 
     @"photoId", [photo GPhotoID]];
  [fetchRequest setPredicate:predicate];
  NSArray *items = [self executeFetchRequest:fetchRequest ];
  [fetchRequest release];
  if(!items) {
//    NSLog(@"Unresolved error %@", error);
    *f = YES;
    return nil;
  }
  if([items count] >= 1) {
    return (Photo *)[items objectAtIndex:0];
  }
  
  return nil;
}

- (void) setLastAdd {
  NSLog(@"setLastAdd");
  self.album.lastAddPhotoAt = [NSDate date];
  [self save];
}

- (void) clearLastAdd {
  NSLog(@"clearLastAdd");
  self.album.lastAddPhotoAt = nil;
  NSError *error = nil;
  error = [self save];
}

- (NSFetchedResultsController *)createFetchedPhotosController {
  
  [NSFetchedResultsController deleteCacheWithName:@"Root"];
  /*
   Set up the fetched results controller.
   */
  // Create the fetch request for the entity.
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  // Edit the entity name as appropriate.
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo"
                                            inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];
  
  NSPredicate *predicate
  = [NSPredicate predicateWithFormat:@"%K = %@", @"album.albumId", album.albumId];
  [fetchRequest setPredicate:predicate];
  
  // Set the batch size to a suitable number.
  [fetchRequest setFetchBatchSize:20];
  
  // Edit the sort key as appropriate.
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp"
                                                                 ascending:YES];
  NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
  
  [fetchRequest setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *aFetchedPhotosController = [[NSFetchedResultsController alloc]
                                                          initWithFetchRequest:fetchRequest
                                                          managedObjectContext:self.managedObjectContext
                                                          sectionNameKeyPath:nil
                                                          cacheName:@"Root"];
  aFetchedPhotosController.delegate = self;
  fetchedPhotosController = aFetchedPhotosController;
  [fetchedPhotosController retain];
  
  [aFetchedPhotosController release];
  [fetchRequest release];
  [sortDescriptor release];
  [sortDescriptors release];
  NSLog(@"new fetchedPhotosController created.");
  NSError *error;
  [fetchedPhotosController performFetch:&error];
  return fetchedPhotosController;
}


@end
