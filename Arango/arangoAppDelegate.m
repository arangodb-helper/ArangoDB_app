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

@synthesize myTask;

- (int) runSystemCommand:(NSString*) cmd
{
  myTask = [[NSTask alloc]init];
  [myTask setLaunchPath:@"/bin/sh"];
  NSLog( @"%@" , [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/" ]  stringByAppendingString:cmd]);
  [myTask setArguments:[NSArray arrayWithObjects:@"-c", [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/" ]  stringByAppendingString:cmd], nil]];
  myTask.terminationHandler = ^(NSTask *task) {
    NSLog(@"Terminated");
    NSLog([NSString stringWithFormat:@"%l",[task terminationReason]]);
  };
//  NSLog([NSString stringWithFormat:@"%i",[myTask processIdentifier]]);
  [myTask launch];
//  NSLog([NSString stringWithFormat:@"%i",[myTask terminationReason]]);
  return [myTask processIdentifier];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  NSLog( @"%@" , [[NSBundle mainBundle] bundlePath] );
  NSLog([NSString stringWithFormat:@"%i",[self runSystemCommand:@"arangod"]]);
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
  [myTask terminate];
}

@end
