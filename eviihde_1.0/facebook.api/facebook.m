//
//  facebook.m
//  eViihde
//
//  Created by Sami Siuruainen on 22.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import "facebook.h"


@implementation facebook

- (bool) fbLogin:(NSString *)user password:(NSString *)pass {
	
	return false;
}

- (void) checkToken {
	cnfController *cnf;
	cnf = [[cnfController alloc] init];

	if ( [ cnf getBoolCnf:@"disableFacebook" ] )
	{
		
	} else {
		//NSLog(@"len:%d", [ (NSString *) [ cnf getStringCnf:@"fb_access_token" ] length]);
		//if ( ![(NSString *) [ cnf getStringCnf:@"fb_access_token" ] length] )
		//{
			NSString *response;	
			NSURLResponse *Uresponse;	
			NSError *error = nil;
			NSData *data;  
			
			NSLog(@"[ authorize @ gui_1/login ]----------------------------------------------------------------------------------------------------------------");
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: @"https://graph.facebook.com/oauth/authorize?type=user_agent&scope=offline_access,publish_stream,create_event&client_id=106219119443269&redirect_uri=http://www.eviihde.com/fb_callback.php&display=wap" ] cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 30];      
			data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
			response = [NSString stringWithUTF8String: [data bytes]];  
			/*
			if ([Uresponse respondsToSelector:@selector(allHeaderFields)]) {
				NSLog(@"%@", response);
				NSDictionary *dictionary = [Uresponse allHeaderFields];
				NSLog(@"%@", [dictionary description]);
			}
			*/
			if ( [[ response substringToIndex:7] compare:@"<script"] ) {
				NSLog(@"%@", response);
				[ cnf setStringCnf:@"fb_access_token" value:@"" ];
				NSRunAlertPanel(@"eViihde", @"Facebook oikeuksia ei voitu tarkistaa. Varmista asetuksista että eViihde GUI on sallittu ohjelma Facebookissa.", @"Ok", nil, nil);
			} else {
				// We are authoriced, collect code=XXX
				NSLog(@"new_token: %@", response);
				
				NSRange codeLocS=[ response rangeOfString:@"access_token="];
				NSString * codeString = [ response substringFromIndex: codeLocS.location + 13 ];
				NSRange codeLocE = [ codeString rangeOfString:@"&expires"];
				codeString = [ codeString substringToIndex: codeLocE.location ];		
				NSLog(@"FB Access Token: %@", codeString);
				
				NSRange uidLocS = [ codeString rangeOfString:@"-" ];
				NSString * fbUID = [ codeString substringFromIndex: uidLocS.location + 1 ];
				NSRange uidLocE = [ fbUID rangeOfString:@"%" ];
				fbUID = [ fbUID substringToIndex:uidLocE.location ];
				NSLog(@"fbUID:%@", fbUID);
				[ cnf setStringCnf:@"fb_access_token" value:codeString ];
				[ cnf setStringCnf:@"fb_uid" value:fbUID ];
			}				
		//}
	}	
}

- (NSString *) setStatus:(NSString *)fbMessage {
	cnfController *cnf;
	cnf = [[cnfController alloc] init];
	
	//[ self checkToken ];
	
	NSData* requestData = [
						   [ NSString stringWithFormat:
							@"access_token=%@&message=%@", 
							[ cnf getStringCnf:@"fb_access_token" ],
							fbMessage
							] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString* requestDataLengthString = [[NSString alloc] initWithFormat:@"%d", [requestData length]];	
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: @"https://graph.facebook.com/me/feed"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:requestData];
	[request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
	[request setTimeoutInterval:30.0];
	
	
	NSString *response;	
	NSURLResponse *Uresponse;	
	NSError *error = nil;
	NSData *data;  
	
	data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
	response = [NSString stringWithUTF8String: [data bytes]];  
	return response;	
}

- (NSString *) postToFeed:(NSString *)fbMessage fbLink:(NSString *)fbLink fbPicture:(NSString *)fbPicture fbName:(NSString *)fbName fbCaption:(NSString *)fbCaption fbDescription:(NSString *)fbDescription {

	cnfController *cnf;
	cnf = [[cnfController alloc] init];

	//[ self checkToken ];

	if ( fbPicture == @"" ) {
		fbPicture = @"http://www.eviihde.com/tickets_fb.png";
	}
	
	NSData* requestData = [
						   [ NSString stringWithFormat:
							@"access_token=%@&message=%@&link=%@&name=%@&caption=%@&picture=%@&description=%@&privacy={\"value\": \"ALL_FRIENDS\"}", 
							[ cnf getStringCnf:@"fb_access_token" ],
							fbMessage,
							fbLink,
							fbName,
							fbCaption,
							fbPicture,
							fbDescription
							] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString* requestDataLengthString = [[NSString alloc] initWithFormat:@"%d", [requestData length]];	
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: @"https://graph.facebook.com/me/feed"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:requestData];
	[request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
	[request setTimeoutInterval:30.0];
	
	
	NSString *response;	
	NSURLResponse *Uresponse;	
	NSError *error = nil;
	NSData *data;  
	
	data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
	response = [NSString stringWithUTF8String: [data bytes] ];  
	return response;
}

- (NSString *) postLink:(NSString *)fbLink fbPicture:(NSString *)fbPicture fbName:(NSString *)fbName fbCaption:(NSString *)fbCaption fbDescription:(NSString *)fbDescription {
	return [ self postToFeed:@"" fbLink:fbLink fbPicture:fbPicture fbName:fbName fbCaption:fbCaption fbDescription:fbDescription ];
}

- (NSString *) createEvent:(NSString *)fbEventName fbDescription:(NSString *)fbDescription fbStart_time:(NSString *)fbStart_time fbEnd_time:(NSString *)fbEnd_time fbLocation:(NSString *)fbLocation fbPrivacy:(NSString *)fbPrivacy {
	cnfController *cnf;
	cnf = [[cnfController alloc] init];
	
	if ( fbPrivacy == @"" ) {
		fbPrivacy = @"SECRET";
	}
	
	NSData* requestData = [
						   [ NSString stringWithFormat:
							@"access_token=%@&name=%@&description=%@&start_time=%@&end_time=%@&location=%@&privacy_type=%@", 
							[ cnf getStringCnf:@"fb_access_token" ],
							fbEventName,
							fbDescription,
							fbStart_time,
							fbEnd_time,
							fbLocation,
							fbPrivacy
							] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSString* requestDataLengthString = [[NSString alloc] initWithFormat:@"%d", [requestData length]];	
	
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString: @"https://graph.facebook.com/me/events"]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:requestData];
	[request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
	[request setTimeoutInterval:30.0];
	
	
	NSString *response;	
	NSURLResponse *Uresponse;	
	NSError *error = nil;
	NSData *data;  
	
	data = [NSURLConnection sendSynchronousRequest: request returningResponse: &Uresponse  error: &error];  
	response = [NSString stringWithUTF8String: [data bytes] ];  
	return response;	
}


/** TODO: SetFacebookStatus
 curl 
	-F 'access_token=...' \
	-F 'message=This is my status update' \
	https://graph.facebook.com/me/feed 
 **/

/** TODO: Token Error 
 {
 "error": {
 "type": "OAuthException",
 "message": "Error validating access token."
 }
 }
 
 {
 "error": {
 "type": "OAuthException",
 "message": "An active access token must be used to query information about the current user."
 }
 }
 
 **/

@end