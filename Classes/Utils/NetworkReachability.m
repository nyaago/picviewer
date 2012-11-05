//
//  NetworkReachability.m
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

#import <SystemConfiguration/SystemConfiguration.h>
#import <string.h>
#import <netinet/in.h>
#import "NetworkReachability.h"


@implementation NetworkReachability

+ (BOOL)reachable {
  BOOL result = NO;
  //  Create Internet socket addr of zero
	struct sockaddr_in zeroAddr;
  memset(&zeroAddr, 0, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
  
	// Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = 
  SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
  
	// Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
  
	// Create output
	if (flags & kSCNetworkFlagsReachable)
    result = YES;
	else
    result = NO;
  

  return result;
}

+ (BOOL)reachableByWifi {
  BOOL result = NO;
  // Create Internet socket addr of zero
	struct sockaddr_in zeroAddr;
  memset(&zeroAddr, 0, sizeof(zeroAddr));
	zeroAddr.sin_len = sizeof(zeroAddr);
	zeroAddr.sin_family = AF_INET;
  
	// Create target in format need by SCNetwork
	SCNetworkReachabilityRef target = 
  SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddr);
  
	// Get the flags
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityGetFlags(target, &flags);
  
	// Create output
	if ( (flags & kSCNetworkFlagsReachable ) && 
      !(flags & kSCNetworkFlagsTransientConnection))
    result = YES;
	else
    result = NO;
  
  
  return result;
  
}

@end
