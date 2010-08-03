//
//  SettingsManager.h
//  PicasaViewer
//
//  Created by nyaago on 10/05/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
