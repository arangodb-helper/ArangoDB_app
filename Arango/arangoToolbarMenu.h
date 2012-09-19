//
//  arangoToolbarMenu.h
//  Arango
//
//  Created by Michael Hackstein on 06.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class arangoAppDelegate;
@class arangoCreateNewDBWindowController;
@class arangoUserConfigController;
@interface arangoToolbarMenu : NSMenu


@property (assign) NSMenuItem* createDB;
@property (assign) NSMenuItem* configure;
@property (assign) NSMenuItem* quit;
@property (retain) arangoCreateNewDBWindowController* createNewWindowController;
@property (retain) arangoUserConfigController* configurationViewController;
@property (retain) arangoAppDelegate* appDelegate;


- (id) initWithAppDelegate:(arangoAppDelegate*) aD;
- (void) showConfiguration;
- (void) updateMenu;
- (void) quitApplication;
- (void) createNewInstance;
@end
