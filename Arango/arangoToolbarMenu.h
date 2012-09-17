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


@property (retain) NSMenuItem* createDB;
@property (retain) NSMenuItem* configure;
@property (retain) NSMenuItem* quit;
@property (strong) arangoCreateNewDBWindowController* createNewWindowController;
@property (strong) arangoUserConfigController* configurationViewController;
@property (weak) arangoAppDelegate* appDelegate;


- (id) initWithAppDelegate:(arangoAppDelegate*) aD;
- (void) updateMenu;
- (void) quitApplication;
- (void) createNewInstance;
@end
