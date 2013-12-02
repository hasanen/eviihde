//
//  general.h
//  eViihde
//
//  Created by Sami Siuruainen on 4.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

@interface general : NSObject {

}

- (NSString*) maxDate:(NSString *)shortDate;
- (NSString*) urlEncode:(NSString *)stringToEncode;
- (NSString *) returnMD5Hash:(NSString*)concat;
- (NSString *) MD5Hash:(NSString*)concat;

@end
