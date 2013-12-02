//
//  facebook.h
//  eViihde
//
//  Created by Sami Siuruainen on 22.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "cnfController.h"

@interface facebook : NSObject {

}

- (bool) fbLogin:(NSString *)user password:(NSString *)pass; 
- (void) checkToken;

- (NSString *) setStatus:(NSString *)fbMessage;
- (NSString *) postToFeed:(NSString *)fbMessage fbLink:(NSString *)fbLink fbPicture:(NSString *)fbPicture fbName:(NSString *)fbName fbCaption:(NSString *)fbCaption fbDescription:(NSString *)fbDescription;
- (NSString *) postLink:(NSString *)fbLink fbPicture:(NSString *)fbPicture fbName:(NSString *)fbName fbCaption:(NSString *)fbCaption fbDescription:(NSString *)fbDescription;
- (NSString *) createEvent:(NSString *)fbEventName fbDescription:(NSString *)fbDescription fbStart_time:(NSString *)fbStart_time fbEnd_time:(NSString *)fbEnd_time fbLocation:(NSString *)fbLocation fbPrivacy:(NSString *)fbPrivacy;

@end
