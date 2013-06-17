//
//  ModelController.h
//  PicasaViewer
//
//  Created by nyaago on 2013/06/17.
//
//

#import <Foundation/Foundation.h>

@interface ModelController : NSObject

/*!
 @property managedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (id) initWithContext:(NSManagedObjectContext *)context;
- (NSError *) save;
- ( NSArray *) executeFetchRequest:(NSFetchRequest *)fetchRequest;
- (id)insertNewObjectForEntityForName:(NSString *)name;
-(void)performInvocation:(NSInvocation *)anInvocation;

@end
