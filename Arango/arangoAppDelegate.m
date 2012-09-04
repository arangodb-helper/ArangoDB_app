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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [self startArango];
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
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  [statusItem setMenu: statusMenu];
  [statusItem setImage: [NSImage imageNamed:@"arangoStatusLogo"]];
  [statusItem setHighlightMode:YES];
}

@end
