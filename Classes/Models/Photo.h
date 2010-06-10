//
//  Photo.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhotoImage;

@interface Photo : NSManagedObject {

}
@property (nonatomic, retain) NSManagedObject * photoImage;

@property (nonatomic, retain) NSString * albumId;
//@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * photoId;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * urlForContent;
@property (nonatomic, retain) NSString * urlForThumbnail;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSString * descript;
@property (nonatomic, retain) NSString * location;


@end


/*!
 // AlbumエントリーのManagedObjectの
 // 関連する下位EntityのObjectを追加するためのクラスカテゴリー
 // (実装は自動的的に生成される）
 */
@interface Photo (CoreDataGeneratedAccessors)
- (void)setPhotoImage:(NSManagedObject *)value;
//- (void)removePhotoImageObject:(NSManagedObject *)value;
//- (void)addPhotoImage:(NSSet *)value;
//- (void)removePhotoImage:(NSSet *)value;

@end

