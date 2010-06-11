//
//  NetworkReachability.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NetworkReachability : NSObject {

}

/*!
 @method reachable
 @discussion ネットワーク接続が可能であるかを調べる
 */
+ (BOOL)reachable;

@end
