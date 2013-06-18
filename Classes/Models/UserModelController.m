//
//  UserModelController.m
//  PicasaViewer
//
//  Created by nyaago on 2013/06/18.
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

#import "UserModelController.h"

@implementation UserModelController

- (void)deleteUser:(User *)user {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [self.managedObjectContext performSelector:@selector(deleteObject:)
                                    onThread:[NSThread mainThread]
                                  withObject:user
                               waitUntilDone:YES];
  
  // Save the context.
  NSError *error = [self save];
  if (error) {
    //
    NSLog(@"Unresolved error %@", error);
  }
  [pool drain];
  return;
}


@end
