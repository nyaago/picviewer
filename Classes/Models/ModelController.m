//
//  ModelController.m
//  PicasaViewer
//
//  Created by nyaago on 2013/06/17.
//
//

#import "ModelController.h"

@implementation ModelController
@synthesize managedObjectContext;

- (id) initWithContext:(NSManagedObjectContext *)context  {
  self = [self init];
  if(self) {
    managedObjectContext = [context retain];
  }
  return self;
}

- (void) dealloc {
  if(managedObjectContext)
    [managedObjectContext release];
  [super dealloc];
}

- (NSError *) save {
  
  NSError **error;
  // セレクターの作成
	SEL selector = @selector(save:);
	// シグネチャを作成
	NSMethodSignature *signature = [[managedObjectContext class] instanceMethodSignatureForSelector:selector];
	// invocationの作成
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  
  [invocation setTarget:managedObjectContext];
  [invocation setArgument:&error atIndex:2];
  [invocation setSelector:selector];
  
  if([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
    [self performSelector:@selector(performInvocation:)
               withObject:invocation];
  }
  else {
    [self performSelector:@selector(performInvocation:)
                 onThread:[NSThread mainThread]
               withObject:invocation
            waitUntilDone:YES];
  }
  BOOL retVal;
  [ invocation getReturnValue:( void * ) &retVal ];
  if(!retVal)
    return *error;
  else
    return nil;
}

- ( NSArray *) executeFetchRequest:(NSFetchRequest *)fetchRequest {
  
  NSError **error;
  // セレクターの作成
	SEL selector = @selector(executeFetchRequest:error:);
	// シグネチャを作成
	NSMethodSignature *signature = [[managedObjectContext class] instanceMethodSignatureForSelector:selector];
	// invocationの作成
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  
  [invocation setTarget:managedObjectContext];
  [invocation setArgument:&fetchRequest atIndex:2];
  [invocation setArgument:&error atIndex:3];
  [invocation setSelector:selector];
  
  if([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
    [self performSelector:@selector(performInvocation:)
               withObject:invocation];
  }
  else {
    [self performSelector:@selector(performInvocation:)
                 onThread:[NSThread mainThread]
               withObject:invocation
            waitUntilDone:YES];
  }
  NSArray *retVal;
  [ invocation getReturnValue:( void * ) &retVal ];
  if(retVal)
    return retVal;
  else
    return nil;
}

- (id)insertNewObjectForEntityForName:(NSString *)name {
  // セレクターの作成
	SEL selector = @selector(insertNewObjectForEntityForName:inManagedObjectContext:);
	// シグネチャを作成
	NSMethodSignature *signature = [[NSEntityDescription class] methodSignatureForSelector:selector];
	// invocationの作成
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
  [invocation setTarget:[NSEntityDescription class]];
  [invocation setArgument:&name atIndex:2];
  [invocation setArgument:&managedObjectContext atIndex:3];
  [invocation setSelector:selector];
  
  if([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
    [self performSelector:@selector(performInvocation:)
               withObject:invocation];
  }
  else {
    [self performSelector:@selector(performInvocation:)
                 onThread:[NSThread mainThread]
               withObject:invocation
            waitUntilDone:YES];
  }
  NSArray *retVal;
  [ invocation getReturnValue:( void * ) &retVal ];
  if(retVal)
    return retVal;
  else
    return nil;
}


-(void)performInvocation:(NSInvocation *)anInvocation{
	[anInvocation invoke];
}




@end
