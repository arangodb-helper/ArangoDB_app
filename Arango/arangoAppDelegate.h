//
//  arangoAppDelegate.h
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class arangoToolbarMenu;
@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) arangoToolbarMenu* statusMenu;
@property (retain) NSStatusItem * statusItem;

- (void) startNewArangoWithPath:(NSString*) path andPort: (NSInteger) port andLog: (NSString*) logPath andAlias:(NSString*) alias;

@end
