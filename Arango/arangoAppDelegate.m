//
//  arangoAppDelegate.m
//  Arango
//
//  Created by Michael Hackstein on 28.08.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoAppDelegate.h"
#import <Foundation/NSTask.h>

@implementation arangoAppDelegate

@synthesize arango;
@synthesize statusMenu;
@synthesize statusItem;

NSString* adminDir;
NSString* jsActionDir;
NSString* jsModPath;


- (void) startArango
{
  NSString* arangoPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod"];
  NSString* configPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/arangod.conf"];
  arango = [[NSTask alloc]init];
  [arango setLaunchPath:arangoPath];
  [arango setArguments:[NSArray arrayWithObjects:@"--config", configPath, @"--exit-on-parent-death", @"true", nil]];
  arango.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated Arango");
  };
  [arango launch];
}


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


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  //[self startArango];
  [self startArangoWithPath:@"/arangoTestDB/" andPort:[NSNumber numberWithInt:1337] andLog:@"/arangoLogs/testLog.log"];
//  [self startArangoWithPath:@"/arangoTestDB2" andPort:[NSNumber numberWithInt:1338] andLog:@"/arangoLogs/testLog2.log"];
}

- (IBAction) quitApplication
{
  [[NSApplication sharedApplication] terminate:nil];
}

//- (void) applicationWillTerminate:(NSNotification *)notification
//{
//  [arango terminate];
//}


-(void) awakeFromNib
{
  adminDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/html/admin"];
  jsActionDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/actions/system"];
  jsModPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/server/modules;"] stringByAppendingString:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/js/common/modules"]];
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [statusItem setMenu: statusMenu];
  [statusItem setImage: [NSImage imageNamed:@"arangoStatusLogo"]];
  [statusItem setHighlightMode:YES];
}

@end
