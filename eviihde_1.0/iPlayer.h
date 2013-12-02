//
//  iPlayer.h
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


#import <Cocoa/Cocoa.h>
#import <VLCKit/VLCKit.h>

@interface iPlayer : NSObject {
    NSPanel *iPlayerPanel;

	IBOutlet VLCVideoView * videoView;
	IBOutlet NSView * playerView;	
	IBOutlet NSView * contentView;
	IBOutlet NSSlider * playLocation;
	IBOutlet NSComboBox * cbSubtitles;
	IBOutlet NSComboBox * cbAudioTracks;
	BOOL isPlaying;
	VLCMediaPlayer * player;
}

@property (assign) IBOutlet NSPanel *iPlayerPanel;
@property (assign) IBOutlet VLCVideoView * videoView;

- (IBAction) btRollFW:(id) sender;
- (IBAction) btRollRW:(id) sender;
- (IBAction) btPlay:(id) sender;

- (IBAction) btFullScreen:(id) sender;

- (void) updateLocation;
- (void) sliderChange:(id) sender;
- (void) playContent;
- (id) initWithStream:(NSString *) streamUrl;

NSString * contentUrl;
NSRect fsRect;	
NSTimer * locationUpdate;

int iPNibLoop;

@end
