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
@interface arangoToolbarMenu : NSMenu


@property (retain) NSMenuItem* createDB;
@property (retain) NSMenuItem* quit;
@property (retain) arangoCreateNewDBWindowController* createNewWindowController;
@property (weak) arangoAppDelegate* appDelegate;


- (id)initWithAppDelegate:(arangoAppDelegate*) aD;
- (void) updateMenu;
- (void) quitApplication;
- (void) createNewInstance;
@end
