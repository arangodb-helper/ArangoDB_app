//
//  arangoToolbarMenu.h
//  Arango
//
//  Created by Michael Hackstein on 06.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "arangoCreateNewDBWindowController.h"

@interface arangoToolbarMenu : NSMenu


@property (retain) NSMenuItem* createDB;
@property (retain) NSMenuItem* quit;
@property (retain) arangoCreateNewDBWindowController* createNewWindowController;

- (void) quitApplication;
- (void) createNewInstance;
@end
