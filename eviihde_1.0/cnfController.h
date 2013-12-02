//
//  cnfController.h
//  eViihde
//
//  Created by Sami Siuruainen on 26.3.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface cnfController : NSObject {
	
}

- (void) createDefaultConf;
- (int) getIntCnf:(NSString *)confKey;
- (NSString *) getStringCnf:(NSString *)confKey;
- (BOOL) getBoolCnf:(NSString *)confKey;
- (void) setIntCnf:(NSString *)confKey value:(int)intValue;
- (void) setStringCnf:(NSString *)confKey value:(NSString *)stringValue;
- (void) setBoolCnf:(NSString *)confKey value:(BOOL)boolValue;

@end
