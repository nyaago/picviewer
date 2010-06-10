//
//  PhotoInfoViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/06/09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo.h"

/*!
 @class PhotoInfoViewController
 @discussion 写真の情報を表示するViewのController
 */

@interface PhotoInfoViewController : UITableViewController {
	Photo *photo;
}

/*!
 @property photo
 @discussion 表示対象のAlbum Object
 */
@property (nonatomic, retain) Photo *photo;

/*!
 @method initWithPhotoObject:
 @discussion 表示対象のPhotoObjectを指定しての初期化
 */
- (id) initWithPhotoObject:(Photo *)photoObject;

@end
