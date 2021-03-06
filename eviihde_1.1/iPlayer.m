//
//  iPlayer.m
//  eViihde
//
//  Created by Sami Siuruainen on 18.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

/**
* Copyright (c) 2009-, Sami Siuruainen / eViihde.com
* All rights reserved.
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the Sami Siuruainen / eViihde.com nor the
*       names of its contributors may be used to endorse or promote products
*       derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
* EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
* DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
* LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "iPlayer.h"


@implementation iPlayer

@synthesize iPlayerPanel;
@synthesize videoView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"appDFL");
	[ self playContent ];
}

#ifndef VLCKITNOK
- (IBAction) close:(id) sender{
	NSLog(@"close");
	isPlaying = NO;
	[player stop];
}

- (BOOL)windowWillClose:(id)sender {
	NSLog(@"windowWillClose");
	//[ locationUpdate invalidate ];
	isPlaying = NO;
	[player stop];
	return YES;	
}

- (BOOL)windowShouldClose:(id)sender 
{ 
	NSLog(@"windowShouldClose");
	isPlaying = NO;
	[ player stop ];
	return YES;
}
#endif

- (id) initWithStream:(NSString *) streamUrl {
	self = [super init];
 	if ( self ) {
		iPNibLoop = 0;
		contentUrl = [ [NSString alloc] initWithString: streamUrl ];
	}
	return self;
}

- (void) awakeFromNib
{	
#ifndef VLCKITNOK
	if (iPNibLoop == 0) {
		[ self playContent ];	
		//[playerView setDoubleAction:@selector(pathViewDoubleClickAction:)];
		isPlaying = YES;
		iPNibLoop++;
	}
#endif
}

- (void) updateLocation {
#ifndef VLCKITNOK
	NSLog(@"updateLocation");
	if ( [ player isPlaying ] ) {
		NSLog(@"isPlaying");
		if (isPlaying == YES) {
			NSLog(@"isPlaying = YES");
			NSLog(@"%@", playLocation);
			[ playLocation setFloatValue: [ player position ] ];	
			locationUpdate = [NSTimer scheduledTimerWithTimeInterval:0.5
															  target:self
															selector:@selector(updateLocation)
															userInfo:nil
															 repeats:NO];			
		}
	}
#endif
}

- (void) sliderChange:(id) sender {
#ifndef VLCKITNOK
	[ player setPosition: [ playLocation floatValue ] ];
#endif
}

- (void) playContent
{
#ifndef VLCKITNOK
	[ playLocation setFloatValue: [ player position ] ];
	locationUpdate = [NSTimer scheduledTimerWithTimeInterval:0.5
									 target:self
								   selector:@selector(updateLocation)
								   userInfo:nil
									repeats:NO];
	
	[NSApp setDelegate:self];
	[NSBundle loadNibNamed:@"iplayer" owner:self];
	NSLog(@"streamUrl: %@", contentUrl);
	
	// Allocate a VLCVideoView instance and tell it what area to occupy.
	NSRect rect = NSMakeRect(0, 0, 0, 0);
	rect.size = [playerView frame].size; //[iPlayerPanel frame].size;
	
	videoView = [[VLCVideoView alloc] initWithFrame:rect];
	//[[window contentView] addSubview:videoView];
	[ playerView addSubview:videoView ];
	[videoView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
	videoView.fillScreen = YES;
	
	NSLog(@"playing");
	player = [[VLCMediaPlayer alloc] initWithVideoView:videoView];	
	[player setMedia:[VLCMedia mediaWithURL:[ NSURL URLWithString:contentUrl]]];
	[player play];			
	[ iPlayerPanel setIsVisible:YES ];
	[ iPlayerPanel makeKeyAndOrderFront:self ];
#endif
}

- (IBAction) btFullScreen:(id) sender {
#ifndef VLCKITNOK
	if ( [ NSMenu menuBarVisible ] ) {
		fsRect = [iPlayerPanel frame];
		[NSMenu setMenuBarVisible:NO];
		[iPlayerPanel
		 setFrame:[iPlayerPanel frameRectForContentRect:[[iPlayerPanel screen] frame]]
		 //setFrame: [iPlayerPanel frameRectForContentRect: [contentView frame]]
		 display:YES
		 animate:YES
		 ];		
	} else {
		[iPlayerPanel
		 setFrame:[iPlayerPanel frameRectForContentRect:fsRect]
		 display:YES
		 animate:YES
		 ];		
		[NSMenu setMenuBarVisible:YES];
	}

	//SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
	/*
	
	NSWindow * fullscreenWindow = [[NSWindow alloc]
						initWithContentRect:[contentView frame]
						styleMask:NSBorderlessWindowMask
						backing:NSBackingStoreBuffered
						defer:YES
						screen:[iPlayerPanel screen]];
	[fullscreenWindow setLevel:NSFloatingWindowLevel];
	[fullscreenWindow setContentView:[iPlayerPanel contentView]];
	[fullscreenWindow setTitle:[iPlayerPanel title]];
	[fullscreenWindow makeKeyAndOrderFront:nil];
	
	*/
	/*
	NSDictionary* options = [NSDictionary
							 dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithInt:kCGNormalWindowLevel],
							 NSFullScreenModeWindowLevel, nil];
	[playerView enterFullScreenMode:[NSScreen mainScreen]
					   withOptions:options];
	[ playerView addSubview:videoView ];
	[videoView setAutoresizingMask: NSViewHeightSizable|NSViewWidthSizable];
	videoView.fillScreen = YES;
	*/
	
	/*
	int windowLevel;
    NSRect screenRect;
	// Capture the main display
    if (CGDisplayCapture( kCGDirectMainDisplay ) != kCGErrorSuccess) {
        NSLog( @"Couldn't capture the main display!" );
        // Note: you'll probably want to display a proper error dialog here
    }
	// Get the shielding window level
    windowLevel = CGShieldingWindowLevel();
	// Get the screen rect of our main display
    screenRect = [[NSScreen mainScreen] frame]; // Put up a new window
	[ iPlayerPanel setStyleMask:NSBorderlessWindowMask ];
	[ playerView addSubview: videoView ];
	*/
	
	/*
    mainWindow = [[NSWindow alloc] initWithContentRect:screenRect
											 styleMask:NSBorderlessWindowMask
											   backing:NSBackingStoreBuffered
												 defer:NO screen:[NSScreen mainScreen]];
	 [mainWindow setLevel:windowLevel];
	[mainWindow setBackgroundColor:[NSColor blackColor]];
    [mainWindow makeKeyAndOrderFront:nil];
	 */
#endif
}

- (IBAction) btPlay:(id) sender {
	if ( [ player isPlaying ] ) {
		[ player pause ];
	} else {
		[ player play ];
		[ self updateLocation ];
	}
}

- (IBAction) btRollFW:(id) sender {
#ifndef VLCKITNOK
	[ player jumpForward:5000000000 ];
	NSLog(@"%i", 	[player videoCropGeometry]);
#endif	
}
- (IBAction) btRollRW:(id) sender {
#ifndef VLCKITNOK
	[ player jumpBackward:5000000000 ];
#endif
}



@end
