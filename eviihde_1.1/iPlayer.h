//
//  iPlayer.h
//  eViihde
//
//  Created by Sami Siuruainen on 18.10.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

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
