//
//  PhotoImage.h
//  PicasaViewer
//
//  Created by nyaago on 10/05/12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PhotoImage : NSManagedObject {

}

@property (nonatomic, retain) NSManagedObject * photo;

@property (nonatomic, retain) NSData *image;

@end
