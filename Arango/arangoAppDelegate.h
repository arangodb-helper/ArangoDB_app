//
//  arangoAppDelegate.h
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "arangoToolbarMenu.h"

@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

@property (retain) arangoToolbarMenu *statusMenu;
@property (retain) NSStatusItem * statusItem;

- (void) startNewArangoWithPath:(NSString*) path andPort: (NSInteger) port andLog: (NSString*) logPath andAlias:(NSString*) alias;

@end
