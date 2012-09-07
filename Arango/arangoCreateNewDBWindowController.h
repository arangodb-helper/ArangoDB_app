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
@interface arangoCreateNewDBWindowController : NSWindowController
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *dbPathField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *logField;
@property (weak) IBOutlet NSTextField *aliasField;
@property (weak) IBOutlet NSButton *openDBButton;
@property (weak) IBOutlet NSButton *openLogButton;
@property (weak) arangoAppDelegate *appDelegate;
@property (strong) ArangoConfiguration *editedConfig;


- (id)initWithAppDelegate:(arangoAppDelegate*) aD;
- (id)initWithAppDelegate:(arangoAppDelegate*) aD andArango: (ArangoConfiguration*) config;

- (IBAction) openDatabase: (id) sender;
- (IBAction) openLog: (id) sender;
- (IBAction) start: (id) sender;

@end
