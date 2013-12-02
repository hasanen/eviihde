//
//  cnfWindowDelegate.h
//  eViihde
//
//  Created by Sami Siuruainen on 26.3.2010.
//  Copyright 2010 Sami Siuruainen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CalendarStore/CalendarStore.h>
#import "cnfController.h"
#import <WebKit/WebKit.h>

@interface cnfWindowDelegate : NSObject {
	IBOutlet NSBox *cnfOpenWinBox;
	IBOutlet NSPanel *configPanel;
	IBOutlet NSButton *cnfCBShowRecs;
	IBOutlet NSButton *cnfCBShowRecsToCome;
	IBOutlet NSButton *cnfCBShowChanList;
	IBOutlet NSButton *cnfCBShowTopList;
	IBOutlet NSButton *cnfCBKeepLogged;
	IBOutlet NSButton *cnfCBAutoLogin;
	IBOutlet NSButton *cnfUseVLC;
	IBOutlet NSButton *cnfVLCFullScreen;
	IBOutlet NSButton *cnfRecFolderSelect;
	IBOutlet NSButton *cnfAllowContRemoveFromInRecs;
	IBOutlet NSSlider *cnfHTTPTimeoutSlider;
	IBOutlet NSTextField *cnfHTTPTimeoutLabel;
	IBOutlet NSButton *cnfSingleView;
	IBOutlet NSButton *cnfhttpCacheEnabled;
	IBOutlet NSButton *cnfDisableFacebook;
	IBOutlet NSButton *cnfShowLatestOnlyUnwatched;
	IBOutlet NSButton *cnfPathFolderShowBytes;
	IBOutlet NSButton *cnfSyncServer;
	IBOutlet NSButton *cnfGuideSearch;
	IBOutlet NSButton *cnfAutoTrash;
	IBOutlet NSButton *cnfDisplaySmallInfoBox;
	IBOutlet NSButton *cnfEnableTrashCan;
	IBOutlet NSButton *cnfEnableTrashCanAutocreate;
	IBOutlet NSButton *cnfEnableVersionChecking;

	IBOutlet NSButton *cnfSaveLog;
	IBOutlet NSButton *cnfSelectLogFile;
	IBOutlet NSComboBox *cnfSelectLogLevel;
	IBOutlet NSTextField *cnfLogFile;
	IBOutlet NSArrayController *acLogLevels;
	NSMutableArray * maLogLevels;

	IBOutlet NSSlider *cnfHTTPDownloadSpeedSlider;
	IBOutlet NSTextField *cnfHTTPDownloadSpeedLabel;

	IBOutlet NSTabViewItem *tviTheme;
	IBOutlet NSTabViewItem *tviStartup;
	
	IBOutlet NSSegmentedControl *scProvider;
	
	IBOutlet NSTextField *downloadPath;

	IBOutlet NSComboBox *cbThemes;
	NSMutableArray* maThemeList;
	IBOutlet NSArrayController *acThemeList;
	
	IBOutlet NSButton *btSelectDownloadPath;
	
	IBOutlet NSSlider *slICalReminderTime;
	IBOutlet NSTextField *tfICalTimeText;
	
	NSMutableArray* maICalList;
	IBOutlet NSArrayController *acICalList;
	IBOutlet NSComboBox *cbICal;
	
	IBOutlet WebView *wbFaceBookLogin;
	
	IBOutlet NSTextField *cnfSaveAsTemplate;
	IBOutlet NSButton *btSaveAsHelp;
	IBOutlet NSPanel *npSaveAsHelp;
	IBOutlet NSTextField *lbSaveAsHelpText;
	
	IBOutlet NSComboBox *cbSidebarFontSize;
	IBOutlet NSComboBox *cbRecordingFontSize;

}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

- (IBAction)showSettings:(id)sender;
- (IBAction)chCnfCB:(id)sender;
- (IBAction)chTimeoutSlider:(id)sender;
- (IBAction)chDownloadSpeedSlider:(id)sender;
- (IBAction)chResetProgram:(id)sender;
- (IBAction)acSelectDownloadPath:(id)sender;

- (IBAction) themeSelect:(id)sender;

- (IBAction)serviceProviderSelector:(id)sender;

- (IBAction)chIcalReminder:(id)sender;
- (IBAction)cbICalSelect:(id)sender;

- (IBAction)btSaveAsHelp:(id)sender;
- (IBAction)cnfSaveAsTemplateChange:(id)sender;

- (IBAction) pickLogFile:(id)sender;
-(void)selectLogFileEnd:(NSOpenPanel*)panel returnCode:(int)rc contextInfo:(void*)ctx;
- (IBAction) logLevelSelect:(id)sender;

- (IBAction)selectSidebarFontSize:(id)sender;
- (IBAction)selectRecordingFontSize:(id)sender;


@property (copy) NSArray* maThemeList;
@property (copy) NSArray* maICalList;
@property (copy) NSArray* maLogLevels;

cnfController *cnf;

@end
