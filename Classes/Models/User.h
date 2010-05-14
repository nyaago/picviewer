//
//  User.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 UserエントリーのManagedObject
 */
@interface User : NSManagedObject {
}

@property (retain) NSString *userId;
@property (retain) NSDate *timeStamp;
@property (nonatomic, retain) NSData *thumbnail;
@property (nonatomic, retain) NSSet *album;

@end


/*!
// UserエントリーのManagedObjectの
// 関連する下位EntityのObjectを追加するためのクラスカテゴリー
// (実装は自動的的に生成される）
 */
@interface User (CoreDataGeneratedAccessors)

- (void)addAlbumObject:(NSManagedObject *)value;
- (void)removeAlbumObject:(NSManagedObject *)value;
- (void)addAlbum:(NSSet *)value;
- (void)removeAlbum:(NSSet *)value;

@end

