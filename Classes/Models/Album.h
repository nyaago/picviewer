//
//  Album.h
//  PicasaViewer
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

#import <Foundation/Foundation.h>

/*!
 AlbumエントリーのManagedObject
 */
@interface Album : NSObject {

}
@property (retain) NSString *albumId;
@property (retain) NSString *title;
@property (retain) NSString *urlForThumbnail;
@property (retain) NSString *access;
@property (retain) NSDate *timeStamp;
@property (retain) NSString *descript;
@property (retain) NSDate *lastAddPhotoAt;
@property (nonatomic, retain) NSData *thumbnail;
@property (nonatomic, retain) NSNumber *photosUsed;

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

