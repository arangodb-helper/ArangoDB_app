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
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *dbPathField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *aliasField;
@property (weak) IBOutlet NSButton *openDBButton;
@property (weak) arangoAppDelegate *appDelegate;
@property (strong) ArangoConfiguration *editedConfig;
@property (strong) NSNumberFormatter *portFormatter;
@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSButton *abortButton;

// Advanced Menu
@property (weak) IBOutlet NSButton *showAdvanced;
@property (weak) IBOutlet NSTextField *logField;
@property (weak) IBOutlet NSTextField *logLevelLabel;
@property (weak) IBOutlet NSTextField *logLabel;
@property (weak) IBOutlet NSButton *openLogButton;
@property (weak) IBOutlet NSComboBox *logLevelOptions;

- (id)initWithAppDelegate:(arangoAppDelegate*) aD;
- (id)initWithAppDelegate:(arangoAppDelegate*) aD andArango: (ArangoConfiguration*) config;

- (IBAction) openDatabase: (id) sender;
- (IBAction) openLog: (id) sender;
- (IBAction) start: (id) sender;
- (IBAction) disclose: (id) sender;

@end
