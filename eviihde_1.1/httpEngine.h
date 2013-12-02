//
//  httpEngine.h
//  eViihde
//
//  Created by Sami Siuruainen on 16.1.2011.
//  Copyright 2011 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "cnfController.h"
#import "JSON/JSON.h"
#import "httpCache.h"
#import "NSURLConnection-block.h"

@interface httpEngine : NSObject {
	cnfController * cnf;
	httpCache * cacheStorage;
}

- (NSArray *) jsonHttpExec:(NSString *)url error:(NSError *)error;
- (void) httpExec:(NSString *)url error:(NSError *)error;
- (NSString *) httpGet:(NSString *)url error:(NSError *)error;
- (NSData *) httpGetData:(NSString *)url error:(NSError *)error;
- (void) execAsyncGet:(NSString *)url success:(void(^)(NSData *,NSURLResponse *))successBlock_ failure:(void(^)(NSData *,NSError *))failureBlock_ error:(NSError *)error;
- (BOOL) checkJSONContent:(NSString *)content;
//- (id) initWithConfig:(cnfController *)cnfController;
- (id) initWithConfig:(cnfController *)cnfController cacheController:(httpCache *) httpCacheID ;

- (void) cacheOff;
- (void) cacheOn;

@end
