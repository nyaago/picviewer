//
//  URLDownload.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <Foundation/Foundation.h>

@class URLDownload;

@protocol URLDownloadDeleagte
- (void)downloadDidFinish:(URLDownload *)download;
- (void)download:(URLDownload *)download didCancelBecauseOf:(NSException *)exception;
- (void)download:(URLDownload *)download didFailWithError:(NSError *)error;
@optional
- (void)download:(URLDownload *)download didReceiveDataOfLength:(NSUInteger)length;
- (void)download:(URLDownload *)download didReceiveResponse:(NSURLResponse *)response;

@end

@interface URLDownload : NSObject {
  id <URLDownloadDeleagte, NSObject> delegate;
  NSString *directoryPath;
  NSString *filePath;
  NSURLRequest *request;
  NSFileHandle *file;
  NSURLConnection *con;
}
@property(readonly) NSString *filePath;

- (id)initWithRequest:(NSURLRequest *)req directory:(NSString *)dir 
             delegate:(id<URLDownloadDeleagte, NSObject>)dg;
- (void)dealloc;
- (void)cancel;

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end