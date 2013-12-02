//
//  NSURLConnection-block.h
//  eViihde
//
//  Created by Sami Siuruainen on 16.1.2011.
//  Copyright 2011 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <foundation/foundation.h>

@interface NSURLConnection (block)
#pragma mark Class API Extensions
+ (void)asyncRequest:(NSURLRequest *)request success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_;
@end