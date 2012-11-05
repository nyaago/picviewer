//
//  SettingsManager.h
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
 @class SettingsManager
 @discussion 設定項目の管理
 */
@interface SettingsManager : NSObject {

}

/*!
 @property userId
 */
@property (nonatomic, retain) NSString *userId;

/*!
 @property password;
 */
@property (nonatomic, retain) NSString *password;

/*!
 @property imageSize;
 */
@property (nonatomic) NSInteger imageSize;


/*!
 @method setUserId:
 @discussion
 */
- (void) setUserId:(NSString *)userId;

/*!
 @method userId
 @discussion
 */
- (NSString *) userId;

/*!
 @method setPassword
 @discussion
 */
- (void) setPassword:(NSString *)password;

/*!
 @method password
 @discussion
 */
- (NSString *) password;

/*!
 @method setImageSize
 @discussion 画像サイズを設定
 */
- (void) setImageSize:(NSInteger)size;

/*!
 @method imageSize
 @discussion 画像サイズをかえす
 */
- (NSInteger) imageSize;


/*!
 @method setCurrentUser:
 @discussion 現在表示対象になっているユーザを設定
 */
- (void) setCurrentUser:(NSString *)user;

/*!
 @method currentUser
 @discussion 現在表示対象になっているユーザを返す
 */
- (NSString *)currentUser;


/*!
 @method setCurrentAlbum:
 @discussion 現在表示対象になっているアルバムを設定
 */
- (void) setCurrentAlbum:(NSString *)albumId;

/*!
 @method currentUser
 @discussion 現在表示対象になっているアルバムを返す
 */
- (NSString *)currentAlbum;

/*!
 @method imageSizeToIndex
 @discussion 画像サイズからindex取得
 */
+ (NSInteger)imageSizeToIndex:(NSInteger)size;


/*!
 @method indexToImageSize
 @discussion indexから画像サイズを取得
 */
+ (NSInteger)indexToImageSize:(NSInteger)index;

@end
