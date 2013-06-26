//
//  Photo.h
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
@property (nonatomic, retain) NSNumber *changedAtLocal;

@property (nonatomic, retain) NSManagedObject * album;


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

