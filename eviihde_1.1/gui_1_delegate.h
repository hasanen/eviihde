//
//  gui_1_delegate.h
//  eViihde
//
//  Created by Sami Siuruainen on 13.9.2010.
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
#import <IOKit/IOKitLib.h>
#import "cnfController.h"
#import "EMKeychainItem.h"
//#import "JSON/JSON.h"
#import "httpCache.h"
#import <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>
#import "general.h"
#import <CalendarStore/CalendarStore.h>
//#import "downloadUtil.h"
#import "curlier.h"
#import "watched_db.h"
#import <WebKit/WebKit.h>
#import "facebook.h"
#import "httpEngine.h"
#import "IGResizableComboBox.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>

//#import "downloadManager.h"

#ifndef VLCKITNOK
#import "VLCKit/VLCKit.h"
#import "iPlayer.h"
#endif

@interface NSColor (ColorChangingFun)
+ (NSColor*)colorWithHexColorString:(NSString*)inColorString;
+(NSArray*)controlAlternatingRowBackgroundColors;
@end

@interface gui_1_delegate : NSObject //NSResponder // NSObject
{	
	NSWindow *masterWindow;	
	IBOutlet NSWindow *masterWindowOutlet;	
	IBOutlet NSTextField *masterStatusLabel;

	IBOutlet NSSearchField *searchField;
	IBOutlet NSSegmentedControl *masterButtons;
	
	IBOutlet NSTableView *serviceTable;
	IBOutlet NSTableColumn *serviceIcon;
	IBOutlet NSTableColumn *serviceText;
	
	NSMutableArray* maServiceList;
	IBOutlet NSArrayController *acServiceList;
	IBOutlet NSTextFieldCell *tcServiceName;
	
	IBOutlet NSTextField *currentPath;
	IBOutlet NSTextField *currentPathFiller;
	IBOutlet NSTextField *tfCurDirID;
	IBOutlet NSTextField *tfClipBoard;
	IBOutlet NSArrayController *acPathContents;
	NSMutableArray* maPathContents;
	IBOutlet NSTableView *tvPathContents;
	IBOutlet NSTableHeaderView *thPathContents;
	IBOutlet NSTableHeaderCell *hcIcon;
	IBOutlet NSTableHeaderCell *hcName;
	IBOutlet NSTableHeaderCell *hcChanSize;
	IBOutlet NSTableHeaderCell *hcStartTime;
	
	IBOutlet NSTextFieldCell *tcName;
	IBOutlet NSTextFieldCell *tcChanSize;
	IBOutlet NSTextFieldCell *tcStartTime;
	
	IBOutlet NSMenuItem *mnArchive;
	IBOutlet NSMenuItem *mnWindow;
	IBOutlet NSMenuItem *mnCheckUpdates;
	IBOutlet NSMenuItem *mnShowStatusScreen;
	IBOutlet NSMenuItem *mnModify;
	IBOutlet NSMenuItem *mnRestore;
	IBOutlet NSMenuItem *mnMove;
	IBOutlet NSMenuItem *mnEmptyTrash;
	IBOutlet NSMenuItem *favs;
	IBOutlet NSMenuItem *recs;
	IBOutlet NSMenuItem *mnSetUnWatched;
	IBOutlet NSMenuItem *mnActions;
	
	IBOutlet NSPanel *pnFolderEditor;
	IBOutlet NSButton *btFolderEditorOk;
	IBOutlet NSButton *btFolderEditorCancel;
	IBOutlet NSTextField *tfFolderName;
	IBOutlet NSTextField *tfFolderAction;
	IBOutlet NSTextField *tfFolderID;
	
	IBOutlet NSPanel *releaseNotes;
	NSWindow *loginWindow;

	IBOutlet NSPanel *httpLoaderScreen;
	IBOutlet NSProgressIndicator *httpLoaderProgress;
	IBOutlet NSTextField *httpTextField;

	IBOutlet NSPanel *errorInfoPanel;
	IBOutlet NSTextField *errorHeader;
	//IBOutlet NSTextField *errorDesc;
	IBOutlet NSTextView *errorDesc;
	IBOutlet NSButton *errorOKButton;
	
	IBOutlet NSTextField *evUser;
	IBOutlet NSTextField *evPass;
	IBOutlet NSButton *lgButton;
	IBOutlet NSButton *cbRemember;
	IBOutlet NSButton *cbAutoLogin;
	
	IBOutlet NSButton *lauchDownloadButton;
	IBOutlet NSButton *ignoreThisVersion;
	IBOutlet NSTextView *releaseNotesText;
	IBOutlet NSTextField *comparedVersions;
	IBOutlet NSTextField *latestVersionShort;
	
	IBOutlet NSPanel *aboutPanel;
	IBOutlet NSTextView *aboutTextPanel;
	IBOutlet NSTextField *versionTextPanel;
	IBOutlet NSImageView *aboutBackground;	
	IBOutlet NSImageView *aboutIcon;
	
	IBOutlet NSBox *cnfOpenWinBox;
	
	IBOutlet NSPanel *recInfoPanel;
	IBOutlet NSTextField *recProgName;
	IBOutlet NSTextField *recDayChannel;
	IBOutlet NSTextField *recDesc;
	IBOutlet NSImageView *recThumbImage;	
	IBOutlet WebView * wvFB;
	IBOutlet NSTextField *tfAboutRecID;
	IBOutlet NSButton *fbButtonCaller;
	
	/** Theme support **/
	/* login screen */
	IBOutlet NSImageView *frmLoginBackground;
	IBOutlet NSImageView *frmLoginLogo;
	
	/** REC Timer Editor **/
	IBOutlet NSArrayController *acRecEditChan;
	IBOutlet NSArrayController *acRecEditFolder;
	IBOutlet NSButton *btSaveRecEdit;
	IBOutlet NSButton *btCancelRecEdit;
	IBOutlet NSTextField *tfWildcardRecEdit;
	IBOutlet NSComboBox *cbChannelRecEdit;
	IBOutlet NSComboBox *cbFolderRecEdit;	
	IBOutlet NSButton *cbIsWildcard;
	NSMutableArray* maRecChan;
	NSMutableArray* maRecFolder;
	IBOutlet NSPanel *pnRecEditor;
	IBOutlet NSWindow *wnRecView;	
	IBOutlet NSTextField *tfRecID;
	IBOutlet NSTextField *tfEditorProgID;
	
	/** Toolbar **/
	IBOutlet NSToolbar *tbMain;
	IBOutlet NSToolbarItem *tbReloadButton;
	IBOutlet NSToolbarItem *tbPlayButton;
	IBOutlet NSToolbarItem *tbDeleteButton;
	IBOutlet NSToolbarItem *tbInfoButton;
	IBOutlet NSToolbarItem *tbAddButton;
	IBOutlet NSToolbarItem *tbEditButton;
	IBOutlet NSToolbarItem *tbDownloadButton;
	IBOutlet NSToolbarItem *tbIcalButton;
	IBOutlet NSToolbarItem *tbFacebookButton;
	
	/** Restore Trashed **/
	IBOutlet NSComboBox *cbFolderTrashRestore;	
	IBOutlet NSPanel *pnRestoreRec;
	IBOutlet NSButton *btRestoreCancel;
	IBOutlet NSButton *btRestoreOk;
	
	/** Facebook toolbox **/
	IBOutlet NSPanel *pnFacebook;
	IBOutlet NSTextField *tfFacebookProgramID;
	
	/** Facebook toolbox - Comment tab **/
	IBOutlet NSButton *btFacebookCommentOk;
	IBOutlet NSButton *btFacebookCommentCancel;
	IBOutlet NSTextField *tfFacebookCommentProgram;
	IBOutlet NSTextField *tfFacebookCommentChannel;
	IBOutlet NSTextField *tfFacebookCommentTime;
	IBOutlet NSTextView *tfFacebookCommentComment;	
	
	/** Facebook toolbox - Status tab **/
	IBOutlet NSButton *btFacebookStatusOk;
	IBOutlet NSButton *btFacebookStatusCancel;
	IBOutlet NSTextField *tfFacebookStatusProgram;
	IBOutlet NSTextField *tfFacebookStatusChannel;
	IBOutlet NSTextField *tfFacebookStatusTime;
	IBOutlet NSTextView *tfFacebookStatusComment;	
	
	/** Facebook toolbox - Event tab **/
	IBOutlet NSButton *btFacebookEventOk;
	IBOutlet NSButton *btFacebookEventCancel;
	IBOutlet NSTextField *tfFacebookEventProgram;
	IBOutlet NSTextField *tfFacebookEventChannel;
	IBOutlet NSTextField *tfFacebookEventTime;
	IBOutlet NSTextField *tfFacebookEventName;
	IBOutlet NSTextField *tfFacebookEventLocation;
	IBOutlet NSTextView *tfFacebookEventDescription;
	IBOutlet NSDatePicker *tfFacebookEventDatePick;
	IBOutlet NSDatePicker *tfFacebookEventDatePickEnd;
	
	/** dynLog window **/
	NSWindow *dynLogWindow;
	IBOutlet NSTableView *dynLogTable;
	IBOutlet NSArrayController *dynLogController;
	NSMutableArray* maDynLog;
	IBOutlet NSToolbarItem *tbEraseLog;
	IBOutlet NSToolbarItem *tbExportLog;
	IBOutlet NSToolbarItem *tbPrintLog;
	IBOutlet NSToolbarItem *tbOpenLogItem;
	int curLogLevel; // Current log level
	NSString *logPath;
	BOOL writeLog;
	
	/** httpEngine **/
	httpEngine * htEngine;
	
	/** Quick Info Box **/
	IBOutlet NSBox * prgInfoBox;
	IBOutlet NSTextField * quickBoxPrgDateTimeChannel;
	IBOutlet NSTextField * quickBoxPrgInfo;
	IBOutlet NSImageView * quickBoxPrgImage;
	
	/** Server Error Message Box **/
	IBOutlet WebView * serverErrorMessageWebView;
	IBOutlet NSPanel * serverErrorMessageWindow;
}

@property (assign) IBOutlet NSWindow *wnRecView;
@property (assign) IBOutlet NSWindow *loginWindow;
@property (assign) IBOutlet NSWindow *masterWindow;
@property (assign) IBOutlet NSWindow *releaseNotes;
@property (assign) IBOutlet NSWindow *dynLogWindow;
@property (assign) IBOutlet NSPanel * serverErrorMessageWindow;

@property (copy) NSArray* maServiceList;
@property (copy) NSArray* maPathContents;
@property (copy) NSArray* maRecChan;
@property (copy) NSArray* maRecFolder;

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender;

- (IBAction)logIn:(id)sender;
- (IBAction)cbRememberClick:(id)sender;
- (IBAction)cbAutoLoginClick:(id)sender;
- (IBAction)enterLogin:(id)sender;
-(void)keyDown:(NSEvent *)anEvent;

- (IBAction) mnReload:(id)sender;
- (IBAction) mnPlay:(id)sender;
- (IBAction) mnInfo:(id)sender;
- (IBAction) mnDownload:(id)sender;
- (IBAction) mnCopyAddress:(id)sender;
- (IBAction) mnAdd:(id)sender;
- (IBAction) mnDelete:(id)sender;
- (IBAction) mnCheckUpdatesAct:(id)sender;
- (IBAction) mnLogout:(id)sender;
- (IBAction) mnDynLog:(id) sender;
- (IBAction) mnShowStatusScreen:(id)sender;
- (IBAction) mnShowSettings:(id)sender;
- (IBAction) mnShowAbout:(id)sender;
- (IBAction) mnModify:(id)sender;
- (IBAction) mnSetWatched:(id)sender;
- (IBAction) mnSetUnWatched:(id)sender;
- (IBAction) mnRestore:(id)sender;
- (IBAction) mnFacebook:(id)sender;
- (IBAction) mnFacebookEV:(id)sender;
- (IBAction) mnGoToDownloadFolder:(id)sender;

- (void) cleanUpTrashFolderMess;
- (void) checkTrashFolder;
- (IBAction) btRestore:(id)sender;
- (IBAction) btRestoreCancel:(id)sender;
- (IBAction) mnEmptyTrash:(id)sender;
- (void) autoEmptyTrash;

- (IBAction)tvServiceListClick:(id)sender;
- (IBAction)masterButtonsClick:(id)sender;
- (IBAction)launchSearch:(id)sender;

- (IBAction)btHideProgramInfo:(id)sender;
- (IBAction)btShowProgramInfo:(id)sender;
- (IBAction)btReactEnter:(id)sender;

- (IBAction)acRecAboutLaunchFacebook:(id)sender;

- (IBAction) loadPath:(NSString *) folderID parentFolder:(NSString *)parentID;
- (NSString *) getRecPath;
- (void) setPathPrefix:(NSString *) prefixText;
- (IBAction) pathViewClick:(id) sender;
- (IBAction)pathViewDoubleClickAction:(id)sender;
- (void) pushFolder:(NSString *)folderID folderName:(NSString *)folderName;
- (id) popFolder;

- (IBAction)loadServices;

- (IBAction) acEraseLog:(id)sender;
- (IBAction) acExportLog:(id)sender;
- (IBAction) acPrintLog:(id)sender;
- (IBAction) acOpenLogItem:(id)sender;

- (void)acFolRemove;
- (void) acFolRename:(NSString *) newFolderName;
- (void) acFolCreate:(NSString *) newFolderName;
- (void) showRenameFolder;
- (void) showCreateFolder;

- (void) showCreateFolder;
- (IBAction) folderCancel:(id)sender;
- (IBAction) folderOk:(id)sender;

- (void) showCreateEditRecTimer;
- (void) reloadContRecsFolders;
- (void) reloadContRecsChannels;
- (void) loadSubFolder:(NSString *)folderID toArray:(NSArrayController *)folderController deep:(NSString *)fillerString;
- (IBAction)btChangeContRecStatus:(id)sender;
- (IBAction)btSaveRecEditAct:(id)sender;
- (IBAction)btCancelRecEditAct:(id)sender;

- (bool) checkLatestVersion;
- (void) autoVersionCheck;
- (bool) checkLatestVersion:(bool)sendVersionData;
- (bool) checkLatestVersion:(bool)sendVersionData silentCheck:(bool)silentCheck;
- (NSString *) getChangeLog:(NSString *) latestVersion;
- (IBAction)doDownloadLatest:(id)sender;
- (IBAction)doIgnoreThisVersion:(id)sender;
- (void) populateDownload;

//- (bool) checkIsResponseOk:(NSString *) response;
- (void) checkLastKeep;
- (void) keepLogged;

- (IBAction)iaErrorOKButton:(id)sender;
- (void) showErrorPopup:(NSString *)errorHeaderText errorDescText:(NSString *)errorDescText;
- (void) showProgress:(NSString *) requestorString;
- (void) hideProgress:(NSString *) requestorString;
- (void) showProgress;
- (void) hideProgress;
- (void) cancelProgress;
- (void) addDynLog:(NSString *) logEntry entrySeverity:(NSString *) entrySeverity callerFunction:(NSString *) callerFunction;
- (void)saveLogAsDidEnd:(NSOpenPanel*)panel;

- (void) acShowProgInfo:(NSString *) progID;
- (IBAction)acRecDelete:(id)sender;
- (IBAction)acRecWatch:(id)sender;
- (IBAction)acRecCopyURL:(id)sender;
- (IBAction)acRecDownload:(id)sender;
- (void) deleteContinousRec;
- (void) deleteSingleRec;
- (void) deleteSingleRec:(BOOL) shouldConfirm;

- (void) initChanList;
- (void)loadChanGuide:(NSString *) chanName;

- (void) loadInRecList;
- (void)loadContRecs;
- (IBAction)loadTops;
- (BOOL) isInRec:(NSString *) progID;

- (void) addToiCal;

- (void)keyDown:(NSEvent *)event;

- (void) changeFont:(id)tableView size:(CGFloat)fontSize;

/******************************************************************************
 * Generalized ElisaViihde routines
 ******************************************************************************/
- (NSString *) viewIDbyProgID:(NSString *) ProgID;
- (NSString *) getProgramProperty:(NSString *)progID progProperty:(NSString *)progProperty;
- (NSArray *) getProgramPropertyArray:(NSString *) progID;

/******************************************************************************
 * Facebook routines
 ******************************************************************************/
- (void) openFacebookToolbox:(NSDictionary *) programDataDictionary ;
- (IBAction) facebookCommentCancel:(id)sender;
- (IBAction) facebookCommentOk:(id)sender;
- (IBAction) facebookStatusOk:(id)sender;
- (IBAction) facebookEventOk:(id)sender;

- (void) tableViewSelectionDidChange: (NSNotification *) notification;


@end