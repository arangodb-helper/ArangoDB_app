//
//  arangoCreateNewDBWindowController.h
//  Arango
//
//  Created by Michael Hackstein on 04.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class arangoAppDelegate;
@class ArangoConfiguration;
@interface arangoCreateNewDBWindowController : NSWindowController <NSWindowDelegate>
@property (retain) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *dbPathField;
@property (assign) IBOutlet NSTextField *portField;
@property (assign) IBOutlet NSTextField *aliasField;
@property (assign) IBOutlet NSButton *openDBButton;
@property (assign) arangoAppDelegate *appDelegate;
@property (retain) ArangoConfiguration *editedConfig;
@property (retain) NSNumberFormatter *portFormatter;
@property (assign) IBOutlet NSButton *okButton;
@property (assign) IBOutlet NSButton *abortButton;

// Advanced Menu
@property (assign) IBOutlet NSButton *showAdvanced;
@property (assign) IBOutlet NSTextField *logField;
@property (assign) IBOutlet NSTextField *logLevelLabel;
@property (assign) IBOutlet NSTextField *logLabel;
@property (assign) IBOutlet NSButton *openLogButton;
@property (assign) IBOutlet NSComboBox *logLevelOptions;
@property (assign) IBOutlet NSButton *runOnStartup;

- (id)initWithAppDelegate:(arangoAppDelegate*) aD;
- (id)initWithAppDelegate:(arangoAppDelegate*) aD andArango: (ArangoConfiguration*) config;

- (IBAction) openDatabase: (id) sender;
- (IBAction) openLog: (id) sender;
- (IBAction) start: (id) sender;
- (IBAction) abort: (id) sender;
- (IBAction) disclose: (id) sender;

@end
