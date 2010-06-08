//
//  AlbumInfoViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/05/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Album.h"

@interface AlbumInfoViewController : UITableViewController {
	Album *album;
}

/*!
 @property album
 @discussion 表示対象のAlbum Object
 */
@property (nonatomic, retain) Album *album;

/*!
 @method initWithAlbumObject:
 @discussion 表示対象のAlbumObjectを指定しての初期化
 */
- (id) initWithAlbumObject:(Album *)albumObject;


@end
