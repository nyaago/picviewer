//
//  AlbumTableViewControllerDelegate.h
//  PicasaViewer
//
//  Created by nyaago on 2012/10/28.
//
//

#import <Foundation/Foundation.h>

@protocol AlbumTableViewControllerDelegate <NSObject>

/*!
 @method albumTableViewControll:selectAlbum:
 @discuss アルバムが選択されたときのDelegate Method
 @param controller
 @param album 選択されたアルバム
 */
- (void) albumTableViewControll:(AlbumTableViewController *)controller
                    selectAlbum:(Album *)album;

@end
