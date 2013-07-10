//
//  QueuedURLDownloader.m
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

-(void)performInvocation:(NSInvocation *)anInvocation;
/*!
 delegate を実行するthread
 */
- (NSThread *) threadForDelegate;

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

/*!
 @method clean
 @discussion コレクションデーターのクリーン
 */
- (void) clean;



/*!
 @method cleanCanceledDownload:
 @discussion キャンセルされたダウンロード要素の
 後かたずけをする.
 */
- (void) cleanCanceledDownloadElems;


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
  
  con = nil;
  data = nil;
  
  delegate = myDelegate;
  
  URL = RequestURL;
  [URL retain];
  userInfo = info;
  [userInfo retain];
  queuedDownloader = downloader;
  
  return self;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)fragment {
  
  if([self.queuedDownloader stoppingRequired] || [self.queuedDownloader isCompleted]) {
    return;
  }
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"connection:didReceiveData:");

  if(fragment) {
    //NSLog(@"data length = %d", [fragment length]);
  }
  SEL selector;
  if (delegate != nil
      && [delegate respondsToSelector:@selector(didReceiveData:withUserInfo:)]) {
    
    selector = @selector(didReceiveData:withUserInfo:);
    // シグネチャを作成
    NSMethodSignature *signature = [[delegate class] instanceMethodSignatureForSelector:selector];
    // invocationの作成
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:delegate];
    [invocation setArgument:&fragment atIndex:2];
    [invocation setArgument:&userInfo atIndex:3];
    [invocation setSelector:selector];
    if([[self threadForDelegate] isEqual:[NSThread currentThread]] ) {
      [self performSelector:@selector(performInvocation:) withObject:invocation];
    }
    else {
      [self performSelector:@selector(performInvocation:)
                   onThread:[self threadForDelegate]
                 withObject:invocation
              waitUntilDone:NO];
    }
  }
  if(!data) {
    data = [[NSMutableData alloc] init];
  }
  [data appendData:fragment];
  [pool drain];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  
  if([self.queuedDownloader stoppingRequired] || [self.queuedDownloader isCompleted]) {
    return;
  }
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SEL selector;
  NSLog(@"connection:didFailWithError - %@", error);
  if (delegate != nil
      && [delegate respondsToSelector:@selector(downloadDidFailWithError:withUserInfo:)]) {
    
    selector = @selector(downloadDidFailWithError:withUserInfo:);
    // シグネチャを作成
    NSMethodSignature *signature = [[delegate class] instanceMethodSignatureForSelector:selector];
    // invocationの作成
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:delegate];
    [invocation setArgument:&error atIndex:2];
    [invocation setArgument:&userInfo atIndex:3];
    [invocation setSelector:selector];
  
    if([[self threadForDelegate] isEqual:[NSThread currentThread]] ) {
      [self performSelector:@selector(performInvocation:) withObject:invocation];
    }
    else {
      [self performSelector:@selector(performInvocation:)
                   onThread:[self threadForDelegate]
                 withObject:invocation
              waitUntilDone:NO];
    }
  }
  [self.queuedDownloader finishDownload:self];
  [pool drain];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
  
  NSLog(@"started? : %d", self.queuedDownloader.isStarted);
  if([self.queuedDownloader stoppingRequired] || [self.queuedDownloader isCompleted]) {
    return;
  }
  NSLog(@"connection:didReceiveResponse:");

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SEL selector;
//  NSLog(@"connection:didReceiveResponse ");
  if (delegate != nil
      && [ delegate respondsToSelector:@selector(didReceiveResponse:withUserInfo:)]) {
    
    selector = @selector(didReceiveResponse:withUserInfo:);
    // シグネチャを作成
    NSMethodSignature *signature = [[delegate class] instanceMethodSignatureForSelector:selector];
    // invocationの作成
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:delegate];
    [invocation setArgument:&response atIndex:2];
    [invocation setArgument:&userInfo atIndex:3];
    [invocation setSelector:selector];
  
    if([[self threadForDelegate] isEqual:[NSThread currentThread]] ) {
      [self performSelector:@selector(performInvocation:) withObject:invocation];
    }
    else {
      [self performSelector:@selector(performInvocation:)
                 onThread:[self threadForDelegate]
               withObject:invocation
            waitUntilDone:NO];
    }
  }
  [pool drain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

  if([self.queuedDownloader stoppingRequired] || [self.queuedDownloader isCompleted]) {
    return;
  }

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"connection:connectionDidFinishLoading ");
  if(data) {
//    NSLog(@"data length = %d", [data length]);
  }
  if(self.userInfo) {
  }
  SEL selector;
  if (delegate != nil
      && [ delegate respondsToSelector:@selector(didFinishLoading:withUserInfo:)]) {
    
    
    selector = @selector(didFinishLoading:withUserInfo:);
    // シグネチャを作成
    NSMethodSignature *signature = [[delegate class] instanceMethodSignatureForSelector:selector];
    // invocationの作成
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    [invocation setTarget:delegate];
    [invocation setArgument:&data atIndex:2];
    [invocation setArgument:&userInfo atIndex:3];
    [invocation setSelector:selector];
  
    if([[self threadForDelegate] isEqual:[NSThread currentThread]] ) {
      [self performSelector:@selector(performInvocation:) withObject:invocation];
    }
    else {
      [self performSelector:@selector(performInvocation:)
                   onThread:[self threadForDelegate]
                 withObject:invocation
              waitUntilDone:NO];
    }
  }
  [self.queuedDownloader finishDownload:self];
  [pool drain];
}


- (void)dealloc {
  delegate = nil;
  if(userInfo)
    [userInfo release];
  if(con)
    [con release];
  if(URL)
    [URL release];
  if(data)
    [data release];
  [super dealloc];
}

-(void)performInvocation:(NSInvocation *)anInvocation{
	[anInvocation invoke];
}


- (NSThread *) threadForDelegate {
  return self.queuedDownloader.delegateOnMainThread ?
                                [NSThread mainThread] :
                                [NSThread currentThread];
}

@end



@implementation QueuedURLDownloader

@synthesize maxAtSameTime;
@synthesize delegate;
@synthesize completedCount;
@synthesize timeoutInterval;
@synthesize delegateOnMainThread;

- (id) init {
  [self initWithMaxAtSameTime:1];
  delegateOnMainThread = YES;
  return self;
}

- (id) initWithMaxAtSameTime:(NSInteger)count {
  self = [super init];
  if(self == nil)
    return self;
  delegateOnMainThread = YES;
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


- (void) addURL:(NSURL *)URL withUserInfo:(NSDictionary *)info {
  QueuedURLDownloaderElem *elem = [[QueuedURLDownloaderElem alloc] 
                                   initURL:URL 
                                   WithUserInfo:info
                                   withDelegate:self.delegate
                                   withQueuedDownloader:self];
  [lock lock];
  if(queuingFinished || completed) {	// もうURLを追加しないよう通知されているのであればSkip
    [elem release];
  }
  else {
    
    [waitingQueue addObject:elem];
  }
  [lock unlock];
}


- (void)finishQueuing {
  queuingFinished = YES;
}

- (void) start {
  
  [lock lock];
  completed = NO;
  stoppingRequired = NO;
  [lock unlock];

  [NSThread detachNewThreadSelector:@selector(run)
                           toTarget:self 
                         withObject:nil];
}

- (void) requireStopping {
  BOOL running = NO;
  while([lock tryLock] == NO) {
    [NSThread sleepForTimeInterval:0.1f];
  }
  if(!completed && started) {
    running = YES;
  }
  stoppingRequired = YES;
  queuingFinished = YES;
  [lock unlock];
  if(running == YES) {
    NSLog(@"QueuedURLDownloader. requireStopping.");
    NSEnumerator *enumerator = [runningDict keyEnumerator];
    NSString *URL;
    while((URL = (NSString *)enumerator.nextObject )) {
      QueuedURLDownloaderElem *elem = (QueuedURLDownloaderElem *)[runningDict objectForKey:URL];
      NSLog(@"QueuedURLDownloader. cancel connection.");
      [elem.con cancel];
      NSLog(@"QueuedURLDownloader. canceled connection.");
    }
  }
}

- (BOOL) isCompleted {
  BOOL ret;
  [lock lock];
  ret = completed;
  [lock unlock];
  return ret;
}

- (BOOL) stoppingRequired {
  BOOL ret;
  [lock lock];
  ret = stoppingRequired;
  [lock unlock];
  return ret;
  
}

- (BOOL) isStarted {
  BOOL ret;
  [lock lock];
  ret = started;
  [lock unlock];
  return ret;
}

- (void) waitCompleted {
  BOOL ret = NO;
  while (ret == NO) {
    if([lock tryLock] == YES) {
      ret = completed || !started;
      if (ret == YES) {
        completed = YES;
      }
      [lock unlock];
      
      [NSThread sleepForTimeInterval:0.01f];
    }
    else {
      [NSThread sleepForTimeInterval:0.01f];
    }
  }
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
  [self waitCompleted];
  delegate = nil;
  [self clean];
  [waitingQueue release];
  [runningDict release];
  [lock release];
  NSLog(@"QueuedURLDownloader dealloc . completed.");
  [super dealloc];
}


#pragma mark Private

- (void) run {
  [lock lock];
  if(stoppingRequired || completed) {
    completed = YES;
    [lock unlock];
    return;
  }
  started = YES;
  [lock unlock];
  while (1) {
    BOOL downloading = NO;
    //NSLog(@"download running..");
    if([lock tryLock]) {
      if(([waitingQueue  count] == 0 && [runningDict count] == 0 && queuingFinished)
         || stoppingRequired == YES) {
        [lock unlock];
        //NSLog(@"dowload break..");
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
        if(!elem.URL) {
          [lock unlock];
          continue;
        }
        [runningDict setObject:elem forKey:elem.URL];
        NSLog(@"start  connection.");
        downloading = YES;
        [lock unlock];
        [elem.con start];
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
    else {
      [NSThread sleepForTimeInterval:0.01f];
    }
  }
  [self clean];
  [lock lock];
  completed = YES;
  [lock unlock];
  // 中断されたときの通知（delegate実行）
  if(self.stoppingRequired) {
    if(delegate && [delegate respondsToSelector:@selector(dowloadCanceled:)] ) {
      [delegate dowloadCanceled:self];
    }
  }
  // 完了の通知
  if(delegate != nil && [delegate respondsToSelector:@selector(didAllCompleted:)] ) {
    [delegate didAllCompleted:self];
  }
  delegate = nil;
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

- (void) clean {
  [self cleanCanceledDownloadElems];
  [self cleanWaitingdDownloadElems];
  if(runningDict ) {
    [runningDict release];
    runningDict = nil;
  }
  if(waitingQueue) {
    [waitingQueue release];
    waitingQueue = nil;
  }
}

- (void) cleanWaitingdDownloadElems {
  if(waitingQueue) {
    [waitingQueue enumerateObjectsUsingBlock:^(id obj, NSUInteger idex, BOOL *stop){
      [obj release];
    }];
  }
}

- (void) cleanCanceledDownloadElems {
  NSEnumerator *enumerator = [runningDict keyEnumerator];
  if(runningDict ) {
    QueuedURLDownloaderElem *elem;
    while((elem = (QueuedURLDownloaderElem *)enumerator.nextObject )) {
      [elem release];
    }
  }
}


@end
