//
//  arangoAppDelegate.m
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoAppDelegate.h"
#import <Foundation/NSTask.h>
#import "arangoToolbarMenu.h"


@implementation arangoAppDelegate

@synthesize statusMenu;
@synthesize statusItem;


NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;

- (NSTask*) startArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod"];
  NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"];
  NSTask* newArango = [[NSTask alloc]init];
  [newArango setLaunchPath:arangoPath];
  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", configPath,
                        @"--exit-on-parent-death", @"true",
                        @"--server.http-port", port.stringValue,
                        @"--log.file", logPath,
                        @"--server.admin-directory", adminDir,
                        @"--javascript.action-directory", jsActionDir,
                        @"--javascript.modules-path", jsModPath,
                        path, nil];
  [newArango setArguments:arguments];
  newArango.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated Arango");
  };
  [newArango launch];
  return newArango;
}


- (NSTask*) testArangoWithPath:(NSString*) path andPort: (NSNumber*) port andLog: (NSString*) logPath
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod"];
  NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"];
  NSTask* newArango = [[NSTask alloc]init];
  [newArango setLaunchPath:arangoPath];
  NSArray* arguments = [NSArray arrayWithObjects:
                        @"--config", configPath,
                        @"--exit-on-parent-death", @"true",
                        @"--server.http-port", port.stringValue,
                        @"--log.file", logPath,
                        @"--server.admin-directory", adminDir,
                        @"--javascript.action-directory", jsActionDir,
                        @"--javascript.modules-path", jsModPath,
                        @"--javascript.gc-interval", @"1",
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-document.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-edge.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-compactor.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-collection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-simple-query.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-index.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-index-geo.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-cap-constraint.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-unique-constraint.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/tests/shell-hash-index.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-relational.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-complex.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-refaccess-attribute.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-optimiser.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-variables.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-operators.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-noncollection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-refaccess-variable.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-escaping.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-skiplist.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-simple.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-ranges.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-arithmetic.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-ternary.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-logical.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-bind.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-parse.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-hash.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-collection.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-variables.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-queries-geo.js"],
                        @"--javascript.unit-tests", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/tests/ahuacatl-functions.js"],
                        path, nil];
  [newArango setArguments:arguments];
  newArango.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated Arango");
  };
  [newArango launch];
  return newArango;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [self startArangoWithPath:@"/arangoTestDB/" andPort:[NSNumber numberWithInt:1337] andLog:@"/arangoLogs/testLog.log"];
}



-(void) awakeFromNib
{
  adminDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/html/admin"];
  jsActionDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/actions/system"];
  jsModPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/modules:"] stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/modules"]];
  statusMenu = [[arangoToolbarMenu alloc] init];
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [statusItem setMenu: statusMenu];
  [statusItem setImage: [NSImage imageNamed:@"arangoStatusLogo"]];
  [statusItem setHighlightMode:YES];
  [statusMenu setAutoenablesItems: NO];
}

@end
