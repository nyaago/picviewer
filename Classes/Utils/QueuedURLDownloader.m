//
//  QueuedURLDownloader.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "QueuedURLDownloader.h"

/*!
 @class QueuedURLDownloaderElem 
 @discussion ダウンロード要素.ダウンロード元URLごとに生成する.
 URLコネクションの管理、データ取得時の通知メソッドの起動などを行う.
 */
@interface QueuedURLDownloaderElem : NSObject {
@private
  NSDictionary *userInfo;
  NSURL *URL;
  NSObject<QueuedURLDownloaderDelegate> *delegate;
  NSURLConnection *con;
  QueuedURLDownloader *queuedDownloader;
  NSMutableData *data;
}

/*!
 ダウンロード元URL
 */
@property (nonatomic, readonly) NSURL *URL;
/*!
 データ取得、接続などの通知先Delegate
 */
@property (nonatomic, readonly) NSObject<QueuedURLDownloaderDelegate> *delegate;
/*
 ダウンロード元URLへのコネクション
 */
@property (nonatomic, retain) NSURLConnection *con;
/*!
 これを要素として含むDownloader
 */
@property (nonatomic, readonly) QueuedURLDownloader *queuedDownloader;
/*!
 付加情報
 */
@property (nonatomic, readonly) NSDictionary *userInfo;

- (id) initURL:(NSURL *)URL WithUserInfo:(NSDictionary *)info 
  withDelegate:(NSObject<QueuedURLDownloaderDelegate> *) myDelegate
withQueuedDownloader: (QueuedURLDownloader *)downloader;

// NSURLConnection delegate
- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)fragment;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@interface QueuedURLDownloader(Private)

/*!
 @method run
 @discussion 未実行Queueからダウンロード対象情報を取り出し、ダウンローﾄﾞを起動を起動.
 Queueが空になるまで繰り返す.
 */
- (void) run;

/*!
 @method finishDownload:
 @discussion １要素のダウンロードが完了したときの処理. QueuedURLDownloaderElemから通知される.
 後かたずけをする.
 */
- (void) finishDownload:(QueuedURLDownloaderElem *)elem;


@end

@implementation QueuedURLDownloaderElem

@synthesize userInfo;
@synthesize delegate;
@synthesize URL;
@synthesize con;
@synthesize queuedDownloader;

- (id) initURL:(NSURL *)RequestURL 
  WithUserInfo:(NSDictionary *)info 
  withDelegate:(NSObject<QueuedURLDownloaderDelegate> *) myDelegate 
withQueuedDownloader: (QueuedURLDownloader *)downloader {
  self = [super init];
  URL = RequestURL;
  [URL retain];
  userInfo = info;
  [userInfo retain];
  delegate = myDelegate;
  [delegate retain];
  con = nil;
  queuedDownloader = downloader;
  [queuedDownloader retain];
  data = nil;
  return self;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)fragment {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//  NSLog(@"connection:didReceiveData");
  if(fragment) {
    //NSLog(@"data length = %d", [fragment length]);
  }
  if ([delegate respondsToSelector:@selector(didReceiveData:withUserInfo:)])
    [delegate didReceiveData:fragment withUserInfo:userInfo];
  if(!data) {
    data = [[NSMutableData alloc] init];
  }
  [data appendData:fragment];
  [pool drain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"connection:didFailWithError - %@", error);
  if ([delegate respondsToSelector:@selector(downloadDidFailWithError:withUserInfo:)])
    [delegate downloadDidFailWithError:error withUserInfo:userInfo];
  [self.queuedDownloader finishDownload:self];
  [pool drain];
}

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//  NSLog(@"connection:didReceiveResponse ");
  if ([delegate respondsToSelector:@selector(didReceiveResponse:withUserInfo:)])
    [delegate didReceiveResponse:response withUserInfo:userInfo];
  [pool drain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//  NSLog(@"connection:connectionDidFinishLoading ");
  if(data) {
//    NSLog(@"data length = %d", [data length]);
  }
  if(self.userInfo) {
    /*
     NSEnumerator *enumerator = [self.userInfo keyEnumerator];
     id key;
     
     while ((key = [enumerator nextObject])) {
     //  NSLog(@"key = %@, value = %@", key, [self.userInfo valueForKey:key]);
     } 
     */
  }
  if ([delegate respondsToSelector:@selector(didFinishLoading:withUserInfo:)])
    [delegate didFinishLoading:data withUserInfo:userInfo];
  [self.queuedDownloader finishDownload:self];
  [pool drain];
//  NSLog(@"drain");
}


- (void)dealloc {
  if(userInfo)
    [userInfo release];
  if(delegate)
    [delegate release];
  if(con)
    [con release];
  if(URL)
    [URL release];
  if(queuedDownloader)
    [queuedDownloader release];
  if(data)
    [data release];
  [super dealloc];
}

@end




@implementation QueuedURLDownloader

@synthesize maxAtSameTime;
@synthesize delegate;
@synthesize completedCount;
@synthesize timeoutInterval;

- (id) init {
  [self initWithMaxAtSameTime:1];
  return self;
}

- (id) initWithMaxAtSameTime:(NSInteger)count {
  self = [super init];
  if(self == nil)
    return self;
  maxAtSameTime = count;
  waitingQueue = [[NSMutableArray alloc] init];
  runningDict = [[NSMutableDictionary alloc] init];
  queuingFinished = NO;
  completed = NO;
  completedCount = 0;
  timeoutInterval = 10.0;
  lock = [[NSLock alloc] init];
  return self;
}

/*
 - (NSInteger) count {
 return [queue count];
 }
 */

- (void) addURL:(NSURL *)URL withUserInfo:(NSDictionary *)info {
  QueuedURLDownloaderElem *elem = [[QueuedURLDownloaderElem alloc] 
                                   initURL:URL 
                                   WithUserInfo:info
                                   withDelegate:self.delegate
                                   withQueuedDownloader:self];
  [lock lock];
  if(!queuingFinished) {	// もうURLを追加しないよう通知されている。
    [waitingQueue addObject:elem];
  }
  [lock unlock];
}


- (void)finishQueuing {
  queuingFinished = YES;
}

- (void) start {
  
  [NSThread detachNewThreadSelector:@selector(run) 
                           toTarget:self 
                         withObject:nil];
}

- (void) requireStopping {
  [lock lock];
  stoppingRequired = YES;
  [lock unlock];
}

- (BOOL) isCompleted {
  BOOL ret;
  [lock lock];
  ret = completed;
  [lock unlock];
  return ret;
}

- (void) waitCompleted {
  BOOL ret = NO;
  while (YES) {
    [lock lock];
    ret = completed || !started;
    [lock unlock];
    if(ret == YES) {
      if(stoppingRequired && started && 
         [delegate respondsToSelector:@selector(dowloadCanceled)] ) {
        [delegate dowloadCanceled];
      }
      break;
    }
    [NSThread sleepForTimeInterval:0.01f];
  }
}


- (void) run {
  [lock lock];
  started = YES;
  [lock unlock];
  while (1) {
    BOOL downloading = NO;
    [lock lock];
    if([waitingQueue  count] == 0 && [runningDict count] == 0 && queuingFinished || 
       stoppingRequired == YES) {
      [lock unlock];
      break;
    }
    if([waitingQueue count] > 0 && [runningDict count] < maxAtSameTime) {
      // 未実行のもののうちで一番先にQueueに登録されたものを得る
      // autoreleaseのObjectがLeakするので AutoReleasePool
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      QueuedURLDownloaderElem *elem = [waitingQueue objectAtIndex:0];
      [waitingQueue removeObjectAtIndex:0];
      NSURLRequest *request = [[NSURLRequest alloc] 
                               initWithURL:elem.URL 
                               cachePolicy:NSURLRequestUseProtocolCachePolicy 
                               timeoutInterval:timeoutInterval];
      // DownLoadを開始
      elem.con = [[NSURLConnection alloc] initWithRequest:request delegate:elem];
      [request release];
      [runningDict setObject:elem forKey:elem.URL];
      [elem.con start];
      downloading = YES;
      [lock unlock];
      [[NSRunLoop currentRunLoop] run];
      [pool drain];
    }
    else {
      [lock unlock];
    }
    if(downloading == NO) {	// LoopでCPU率があがらないように少しsleep
      [NSThread sleepForTimeInterval:0.01f];
    }
  }
  // 完了の通知
  if(delegate == nil)
    return;
  if([delegate respondsToSelector:@selector(didAllCompleted)] ) {
    [lock lock];
    if(stoppingRequired) {
      [lock unlock];
    }
    else {
      [lock unlock];
      [delegate didAllCompleted];
    }
  }
  [lock lock];
  completed = YES;
  [lock unlock];
}

- (void) finishDownload:(QueuedURLDownloaderElem *)elem {
  NSURL *URL = elem.URL;
  [lock lock];
  if(elem) {
    [runningDict removeObjectForKey:URL];
    [elem release];
    completedCount += 1;
  }
  [lock unlock];
}

- (NSInteger)waitingCount {
  NSInteger result;
  [lock lock];
  result = [waitingQueue count];
  [lock unlock];
  return result;
}


- (NSInteger)runningCount {
  NSInteger result;
  [lock lock];
  result = [runningDict count];
  [lock unlock];
  return result;
}


- (void) dealloc {
  if(delegate) {
    [delegate release];
    delegate = nil;
  }
  [waitingQueue release];
  [runningDict release];
  [lock release];
  [super dealloc];
}

@end
