//
//  NetworkReachability.m
//  PicasaViewer
//
//  Created by nyaago on 10/06/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import <string.h>
#import <netinet/in.h>
#import "NetworkReachability.h"


@implementation NetworkReachability

+ (BOOL)reachable {
  BOOL result = NO;
  // Part 1 - Create Internet socket addr of zero
	struct sockaddr_in zeroAddr;
  memset(&zeroAddr, 0, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
  
	// Part 2- Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = 
  SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
  
	// Part 3 - Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
  
	// Part 4 - Create output
	if (flags & kSCNetworkFlagsReachable)
    result = YES;
	else
    result = NO;
  

  return result;
}

@end
