//
//  Album.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 AlbumエントリーのManagedObject
 */
@interface Album : NSObject {

}
@property (retain) NSString *albumId;
@property (retain) NSString *title;
@property (retain) NSString *urlForThumbnail;
@property (retain) NSDate *timeStamp;
@property (retain) NSString *description;
@property (nonatomic, retain) NSData *thumbnail;

@property (nonatomic, retain) NSSet* photo;
@property (nonatomic, retain) NSManagedObject * user;

@end


/*!
 // AlbumエントリーのManagedObjectの
 // 関連する下位EntityのObjectを追加するためのクラスカテゴリー
 // (実装は自動的的に生成される）
 */
@interface Album (CoreDataGeneratedAccessors)
- (void)addPhotoObject:(NSManagedObject *)value;
- (void)removePhotoObject:(NSManagedObject *)value;
- (void)addPhoto:(NSSet *)value;
- (void)removePhoto:(NSSet *)value;

@end

