//
//  PhotoViewController.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PhotoViewController.h"
#import "Photo.h"
#import "PhotoImage.h"
#import "PhotoInfoViewController.h"
#import "PhotoActionDelegate.h"
#import "NetworkReachability.h"

@interface PhotoViewController(Private)

/*!
 @method frameForPhoro:
 @discussion PhotoのFrameのRectを返す
 */
-(CGRect) viewFrameForImage:(UIImage *)image;

/*!
 @method showImage
 @discussion 写真を表示する。未ダウンロードであれば、thumbnailを表示して、ダウンロード処理を起動
 */
-(void) showImage;

/*!
 @method downloadPhoto:
 @discussion 写真のダウンロードを開始する
 */
- (void) downloadPhoto:(Photo *)photo;

/*!
 @method viewFrame:
 @discussion viewのframeのRectを返す
 */
- (CGRect) viewFrame:(UIDeviceOrientation)orientation;

/*!
 @method tapAction:
 @discussion tap発生時に起動されるAction.
 2tapでなければ、statusbar,navigationbarの表示/非表示切り替えを行う。
 */
- (void) tapAction:(id)arg;


@end

@interface PhotoScrollView : UIScrollView   
{
}

@end

@implementation PhotoScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  [[self nextResponder] touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [[self nextResponder] touchesEnded:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [[self nextResponder] touchesMoved:touches withEvent:event];
}

@end

static NSLock *lockFetchedResultsController;

@implementation PhotoViewController

@synthesize fetchedPhotosController, managedObjectContext;
@synthesize prevButton,nextButton;
@synthesize scrollView;
@synthesize imageView;
@synthesize indexForPhoto;
@synthesize toolbar;
@synthesize pageController;
/*
 // The designated initializer.  Override if you create the controller programmatically 
 // and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */


// Implement viewDidLoad to do additional setup after loading the view, 
// typically from a nib.
// Viewロードの通知 - scrollViewの設定、デバイス回転管理の開始、Downloader初期化
- (void)viewDidLoad {
  NSLog(@"photo view contoller viewDidLoad");
  [super viewDidLoad];
  //
  if(!lockFetchedResultsController)
    lockFetchedResultsController = [[NSLock alloc] init];
  
  // scrollViewの設定
  NSInteger statusBarHeight;
  statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
  CGRect rect = self.view.bounds;
  rect.size.height += statusBarHeight;
  scrollView = [[PhotoScrollView alloc] initWithFrame:rect];
  
  scrollView.maximumZoomScale = 3.0;
  scrollView.minimumZoomScale = 1.0;
  scrollView.delegate = self;
  scrollView.scrollEnabled = YES;
  scrollView.scrollEnabled = YES;
  scrollView.userInteractionEnabled = YES;
  scrollView.bounces = NO;
  scrollView.backgroundColor = [UIColor blackColor];
  scrollView.multipleTouchEnabled = YES;
//  self.view  = scrollView;
  self.view.backgroundColor = [UIColor blackColor];
  [self.view addSubview:scrollView];
  self.wantsFullScreenLayout = YES;
  // デバイス回転の管理
  //deviceRotation = [[DeviceRotation alloc] initWithDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSLog(@"photo view controller view will apear");
}

// View表示時の通知
// Viewのサイズ、toolbarの配置の調整をしてい写真を表示
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"photo view controller view will apear");
  
}

- (void)viewDidDisappear:(BOOL)animated {
  // Download実行中の場合,停止を要求、完了するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    downloader = nil;
  }
}

- (void)viewDidUnload {
  NSLog(@"PhotoViewCOntroller unload");
  [super viewDidUnload];
  /*
   if(fetchedPhotosController) {
   [fetchedPhotosController release];
   fetchedPhotosController = nil;
   }
   */
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return YES;
  // return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}



- (void)dealloc {
  NSLog(@"PhotoViewController dealloc");
  NSLog(@"managedObjectContext retain count = %d", 
        [managedObjectContext retainCount]);
  NSLog(@"prevButton retain count = %d", [prevButton retainCount]);
  NSLog(@"nextButton retain count = %d", [nextButton retainCount]);
  NSLog(@"scrollView retain count = %d", [scrollView retainCount]);
  NSLog(@"imageView retain count = %d", [imageView retainCount]);
  NSLog(@"toolbar retain count = %d", [toolbar retainCount]);
  NSLog(@"downloader retain count = %d", [downloader retainCount]);
  NSLog(@"fetchedPhotosController retain count = %d", 
        [fetchedPhotosController retainCount]);
  NSLog(@"pageController retain count = %d", [pageController retainCount]);
  
  // Download実行中の場合,停止を要求、完了するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [downloader release];
  }
  
  if(managedObjectContext)
    [managedObjectContext release];
  [prevButton release];
  [nextButton release];
  [scrollView release];
  if(imageView)
    [imageView release];
  [toolbar release];
  if(fetchedPhotosController) {
    [fetchedPhotosController release];
    fetchedPhotosController = nil;
  }
  if(pageController)
    [pageController release];
  if(deviceRotation)
    [deviceRotation release];
  [super dealloc];
}

#pragma mark -

#pragma mark PhotoViewController


- (Photo *)photoAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  [pool drain];
  return photoObject;
}  

- (UIView *)thumbnailAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  UIView *imgView = nil;
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  [lockFetchedResultsController lock];
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  [lockFetchedResultsController unlock];
  UIImage *image = nil;
  if(photoObject.thumbnail) {
    image  = [UIImage imageWithData:photoObject.thumbnail];
    imgView = [[UIImageView alloc] initWithImage:image];
  }
  else {
    imgView = [[UIImage alloc] init];
  }
  imgView.frame = [self viewFrameForImage:image];
  [pool drain];
  return imgView;
}

- (UIView *)photoImageAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"Photo view controller photoImageAt");
  UIView *imgView = nil;
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  [lockFetchedResultsController lock];
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  [lockFetchedResultsController unlock];
  UIImage *image = nil;
  if(photoObject.photoImage) {
    PhotoImage *photoImage = (PhotoImage *)photoObject.photoImage;
    if(photoImage.image && [photoImage.image length] > 0) {
      NSLog(@"image length = %d", [photoImage.image length] );
      image  = [UIImage imageWithData:photoImage.image];
      imgView = [[UIImageView alloc] initWithImage:image];
      imgView.frame = [self viewFrameForImage:image];
    }
  }
  else {
    imgView = nil;
  }
  [pool drain];
  return imgView;
}

- (NSUInteger)photoCount {
  [lockFetchedResultsController lock];
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  [lockFetchedResultsController unlock];
  return [sectionInfo numberOfObjects];
}



- (void) setIndexForPhoto:(NSUInteger)index {
  
  indexForPhoto = index;
}

#pragma mark -


#pragma mark QueuedURLDownloaderDelegate

/*!
 ダウンロードエラー時の通知
 */
- (void)downloadDidFailWithError:(NSError *)error withUserInfo:(NSDictionary *)info {
  NSLog(@"downloadDidFailWithError");
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  if(indexForPhoto >= [self photoCount])
    return;
  if(imageView) {
    if([imageView subviews])
      [imageView removeFromSuperview];
    [imageView release];
    imageView = nil;
  }
  Photo *photo = [self photoAt:indexForPhoto];
  //新しいPhotoImageオブジェクトを作って
  [lockFetchedResultsController lock];
  NSManagedObject *photoImageObject 
  = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoImage"
                                  inManagedObjectContext:managedObjectContext];
  
  [photoImageObject setValue:data forKey:@"image"];
  
  [photo setPhotoImage:photoImageObject];
  NSError *error;
  //  photo.content = data;
  if(![managedObjectContext save:&error] ) {
    NSLog(@"Unresolved error %@", error);
  }
  [lockFetchedResultsController unlock];
  imageView = [self photoImageAt:indexForPhoto];
//  self.scrollView.contentOffset  = CGPointMake(0.0f, 
//                                               (scrollView.bounds.size.height - 
//                                               imageView.bounds.size.height) / 2);
  [self.scrollView addSubview:imageView];
  [downloader release];
  downloader = nil;
  // 
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark -

#pragma mark DeviceRotationDelegate

-(void) deviceRotated:(UIDeviceOrientation)orient {
  return;
  CGFloat angle = 0.0f;
  UIView *v = self.view.superview;
  if(orient == UIDeviceOrientationLandscapeLeft) {
  	angle = M_PI_2;
    v.transform = CGAffineTransformRotate( v.transform, 
                                                         angle);
  }
  else if(orient == UIDeviceOrientationLandscapeRight)  {
  	angle = M_PI_2;
    v.transform = CGAffineTransformRotate( v.transform, 
                                                         angle);
  }
  else  if(orient == UIDeviceOrientationPortraitUpsideDown) {
    angle = M_PI_2;
    v.transform = CGAffineTransformRotate( v.transform, 
                                                         angle);
  }
  else  if(orient == UIDeviceOrientationPortrait) {
		v.transform = CGAffineTransformIdentity;    
  }

 
}
  

#pragma mark Private

-(CGRect) viewFrameForImage:(UIImage *)image {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  CGSize size = image.size;
  CGRect viewRect = self.scrollView.bounds;
  CGRect rect;
  if(size.height / size.width > viewRect.size.height / viewRect.size.width ) { 
    // 画像が縦長
    float rate = viewRect.size.height / image.size.height;
    float width = size.width * rate;
    rect = CGRectMake((viewRect.size.width -  width) / 2, 
                      0.0f, 
                      width, 
                      viewRect.size.height);
    
  }
  else { // 画像が横長
    float rate = viewRect.size.width / image.size.width;
    float height = size.height * rate;
    rect = CGRectMake(0.0f, 
                      (viewRect.size.height - height) / 2, 
//                      0.0f,
                      viewRect.size.width, 
                      height);
  }
  [pool drain];
  return rect;
}

- (CGRect)viewFrame:(UIDeviceOrientation)orientation {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  UIView *v = self.view.superview;
  CGRect rect = v.frame;
  
  // View階層Debug
  v = self.view;
  for(int i = 0; i < 4; ++i) {
    NSLog(@"Class = %@,Page view,x ==> %f, y => %f, width => %f, height => %f ",
          [v class],
          rect.origin.x , rect.origin.y, 
          rect.size.width, rect.size.height
          );
    v = v.superview;
  }
  
  CGRect bounds = self.view.frame;
  //  bounds.size.height += statusBarHeight;
  //  bounds.origin.y = 0 -  statusBarHeight;
  [pool drain];
  return bounds;
}

-(void) showImage {
  NSLog(@"showImage");
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  if(indexForPhoto >= [self photoCount])
    return;
  BOOL mustDownload = NO;
  if(imageView) {
    if([imageView subviews])
      [imageView removeFromSuperview];
    [imageView release];
    imageView = nil;
  }
  imageView = [self photoImageAt:indexForPhoto];
  if(!imageView) {
    imageView = [self thumbnailAt:indexForPhoto];
    mustDownload = YES;
  }
  /*
   CGRect bounds = scrollView.frame;
   NSLog(@"scrollView - x => %f,y => %f, width => %f, height => %f", 
   bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
   bounds = self.view.frame;
   NSLog(@"view - x => %f,y => %f, width => %f, height => %f", 
   bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
   */
  scrollView.contentSize = imageView.frame.size;
//  self.scrollView.contentOffset  = CGPointMake(0.0f, 
//                                                (scrollView.bounds.size.height - 
//                                                imageView.bounds.size.height) / 2);
  [self.scrollView addSubview:imageView];
  /*
   bounds = scrollView.frame;
   NSLog(@"scrollView - x => %f,y => %f, width => %f, height => %f", 
   bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
   bounds = self.view.frame;
   NSLog(@"view - x => %f,y => %f, width => %f, height => %f", 
   bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
   */
  //  Photoがnilだった場合、ダウンロード処理の起動
  if(mustDownload) {
    NSLog(@"down load photo");
    [self downloadPhoto:[self photoAt:indexForPhoto]];
  }
  [pool drain];
}


- (void) downloadPhoto:(Photo *)photo  {
  // Network接続確認
  if(![NetworkReachability reachable]) {
    NSString *title = NSLocalizedString(@"Notice","Notice");
    NSString *message = NSLocalizedString(@"Warn.NetworkNotReachable",
                                          "not reacable");
    UIAlertView *alertView = [[UIAlertView alloc] 
                              initWithTitle:title
                              message:message
                              delegate:nil
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
    return;
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  // downloader初期化
  downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:2];
  downloader.delegate = self;
  // download開始
  [downloader start];
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [downloader addURL:[NSURL URLWithString:photo.urlForContent ]
        withUserInfo:nil];
  [downloader finishQueuing];
  [pool drain];
}

- (void) tapAction:(id)arg {
  if(lastTapCount == 1) {
    [self.pageController changeNavigationAndStatusBar];
  }
}


#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  [[self nextResponder] touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  
  UITouch *touch = [touches anyObject];
  NSLog(@"touch event - touches - %d, tap count = %d",
        [touches count], [touch tapCount]);
  if([touch tapCount] == 2) {
    if(self.scrollView.zoomScale == 1.0f) {
    	self.scrollView.zoomScale = self.scrollView.maximumZoomScale;
    }
    else {
    	self.scrollView.zoomScale = 1.0f;
    }
    lastTapCount = 2;
  }
  else {
    lastTapCount = 1;
    [self performSelector:@selector(tapAction:)
               withObject:nil
               afterDelay:0.5f];
  	[[self nextResponder] touchesEnded:touches withEvent:event];
  }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [[self nextResponder] touchesMoved:touches withEvent:event];
}

#pragma mark -

#pragma mark ScrolledPageViewDelegate protocol

/*!
 @method pageDidAddWithPageScrollViewController:withOrientation
 @discussion このViewがPagingScrollViewに追加されたときの通知
 */
- (void)pageDidAddWithPageScrollViewController:(PageControlViewController *)controller 
                               withOrientation:(UIDeviceOrientation)orientation{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Viewサイズ調整
  self.view.frame = [self viewFrame:orientation];
  CGRect bounds = self.view.frame;
  bounds.origin.x = 0;
  bounds.origin.y = 0;
  self.scrollView.frame = bounds;
  
  // toolBar配置
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y 
  = self.view.frame.size.height - toolbarFrame.size.height ;
  toolbar.frame = toolbarFrame;
  toolbar.hidden = YES;
  [self showImage];
  [self.view bringSubviewToFront:toolbar];
  [pool drain];
}

- (void) pageScrollView:(PageControlViewController *)controller 
                rotated:(UIDeviceOrientation)orientation {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Viewサイズ調整
  self.view.frame = [self viewFrame:orientation];
  CGRect bounds = self.view.frame;
  bounds.origin.x = 0;
  bounds.origin.y = 0;
  self.scrollView.frame = bounds;
  // toolBar配置
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y 
  = self.view.frame.size.height - toolbarFrame.size.height ;
  toolbar.frame = toolbarFrame;
  toolbar.hidden = YES;
  [self showImage];
  [self.view bringSubviewToFront:toolbar];
  [pool drain];
}

- (void) setPageController:(PageControlViewController *)controller {
  if(pageController) {
    if(pageController == controller)
      return;
    [pageController release];
  }
  pageController = controller;
  [pageController retain];
}

/*!
 @method viewInfoAction:
 @discssion 情報表示ボタンのアクション.写真情報表示Viewを表示する.
 */
- (void) viewInfoAction:(PageControlViewController *)parentController  {
  PhotoInfoViewController *viewController = [[PhotoInfoViewController alloc]
                                             initWithNibName:@"PhotoInfoViewController" 
                                             bundle:nil];
  Photo *photo = [self photoAt:indexForPhoto];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  
  viewController.photo= photo;
  [self.view.window bringSubviewToFront:parentController.view];
  [[parentController parentViewController] presentModalViewController:navigationController 
                                                             animated:YES];
  [viewController release];
  [navigationController release];
}


/*!
 @method doAction:
 @discssion Actionボタンのアクション.写真情報表示Viewを表示する.
 */
- (void) doAction:(PageControlViewController *)parentController  {
//  UIActionSheet *actionSheet
  // 送信方法を選択するシートを表示. 選択時の処理は、Delegateに委譲
  Photo *photo = [self photoAt:indexForPhoto];
  PhotoActionDelegate *delegate = [[PhotoActionDelegate alloc] 
                                   initWithPhotoObject:photo 
                                   withParentViewController:pageController];
  UIActionSheet *sheet = [[UIActionSheet alloc] 
                          initWithTitle:NSLocalizedString(@"Photo.Action",@"Select!") 
                          delegate:delegate 
                          cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") 
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Email",@"by email"),
                          NSLocalizedString(@"SaveToLibrary",@"to album"),
                          nil];
  [sheet showInView:parentController.view];                        
}

#pragma mark -

#pragma mark UIScrollViewDelegate


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imageView;
}

/*!
 @method scrollViewDidEndZooming:withView:atScale
 @discussion Zooming時の通知。
 imageViewの縦の配置調整を行う。
 */
/*
- (void)scrollViewDidEndZooming:(UIScrollView *)zoomingScrollView 
                       withView:(UIView *)view 
                        atScale:(float)scale {
  NSLog(@"scrollViewDidEndZooming:");
  NSLog(@"view - w:h = %f:%f", view.bounds.size.width, view.bounds.size.height);
  NSLog(@"scroll view - w:h = %f:%f", zoomingScrollView.bounds.size.width, 
        zoomingScrollView.bounds.size.height);
  NSLog(@"scale = %f", scale);
  float rate = (zoomingScrollView.bounds.size.height / view.bounds.size.height);

  
  CGRect frame = view.frame;
  if (scale > rate ) {  // imageViewがscrollViewより高い場合
//    frame.origin.y = 0;  // 
  }
  else {                // センタリング
    float height = view.bounds.size.height * scale;
//    frame.origin.y = (zoomingScrollView.bounds.size.height - height) / 2;
  }
  view.frame = frame;
  
}
*/

#pragma mark statci Method

+ (UIBarButtonItem *)backButton {
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] 
                  initWithTitle:NSLocalizedString(@"Photos", @"Photos")
                  style:UIBarButtonItemStyleDone 
                  target:nil
                  action:nil ];
	[backButton  autorelease];
  return backButton;
}


@end
