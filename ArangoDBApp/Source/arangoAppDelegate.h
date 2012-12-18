//
//  arangoAppDelegate.h
//
// This is the main controlling class for the ArangoDB.
// It manages all permanent objects and keeps links to the menu.
// Additionally it allows to create/update permanent configurations of Arangos.
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ArangoToolbarMenu;
@class ArangoConfiguration;
@class ArangoUserConfigController;
@class ArangoManager;

@interface arangoAppDelegate : NSObject <NSApplicationDelegate>

// The underlying menu of the status-bar icon.
@property (retain) ArangoToolbarMenu* statusMenu;
// A controller for user-configuration.
@property (retain) ArangoUserConfigController* userConfigController;
// The item in the statusbar, containing the icon as well as an accesspoint for the menu.
@property (retain) NSStatusItem * statusItem;

@property (retain) ArangoManager* manager;


@end
