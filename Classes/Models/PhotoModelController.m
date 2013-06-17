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
  
  NSString *photoId = [photo GPhotoID];
  // 新しい永続化オブジェクトを作って
  Photo *photoObject 
  = (Photo *)[self insertNewObjectForEntityForName:@"Photo"];
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
  if ([self.album respondsToSelector:@selector(addPhotoObject:) ] ) {
    [self.album addPhotoObject:(NSManagedObject *)photoObject];
  }	
  [lockSave lock];
  NSError *error = [self save];
  if (error) {
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
  [lockSave lock];
  NSError *error = [self save];
  if (error) {
    // 
    [lockSave unlock];
    NSLog(@"Unresolved error %@", error);
    return nil;	
  }
  [lockSave unlock];
  return photo;
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
  return;
}    

- (NSFetchedResultsController *)fetchedPhotosController {
  
  if (fetchedPhotosController != nil) {
    return fetchedPhotosController;
  }
  [self performSelectorOnMainThread:@selector(createFetchedPhotosController) withObject:nil waitUntilDone:YES];
  return fetchedPhotosController;
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
  NSError *error;
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
  //NSLog(@"setLastAdd lock");
  //NSError *error = nil;
  [lockSave lock];
  //NSLog(@"setLastAdd locked");
  // @TODO - フリーズする が保存したい...
  //if (![managedObjectContext save:&error]) {
  //}
  //NSLog(@"setLastAdd saved");
  [lockSave unlock];
  //NSLog(@"setLastAdd unlocked");
}

- (void) clearLastAdd {
  NSLog(@"clearLastAdd");
  self.album.lastAddPhotoAt = nil;
  NSError *error = nil;
  [lockSave lock];
  
  error = [self save];
  [lockSave unlock];
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
  return fetchedPhotosController;
}


@end
