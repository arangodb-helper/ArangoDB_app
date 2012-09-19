//
//  arangoUserConfigController.m
//  Arango
//
//  Created by Michael Hackstein on 17.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import "arangoUserConfigController.h"
#import "arangoAppDelegate.h"
#import "User.h"

@interface arangoUserConfigController ()

@end

@implementation arangoUserConfigController
@synthesize putAsStartUp;
@synthesize delegate;
@synthesize rosDefinition;

const NSString* RES = @"Restart all instances running at last shutdown";
const NSString* DEF = @"Define for each instance";
const NSString* ALL = @"Start all instances";
const NSString* NON = @"Do not start instaces";

- (id) initWithAppDelegate: (arangoAppDelegate*) aD
{
  if([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
    self = [super init];
    self.delegate = aD;
    [[NSBundle mainBundle] loadNibNamed:@"arangoUserConfigController" owner:self topLevelObjects:nil];
  } else {
    self = [self initWithWindowNibName:@"arangoUserConfigController" owner:self];
    self.delegate = aD;
  }
  if (self) {
    
    [self.window setReleasedWhenClosed:NO];
    [self.window center];
    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyWindow];
    [self showWindow:self.window];
  }
  return self;
}


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib
{
  [self.rosDefinition addItemWithObjectValue:RES];
  [self.rosDefinition addItemWithObjectValue:DEF];
  [self.rosDefinition addItemWithObjectValue:ALL];
  [self.rosDefinition addItemWithObjectValue:NON];
  NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *userEntity = [NSEntityDescription entityForName:@"User" inManagedObjectContext: [self.delegate getArangoManagedObjectContext]];
  [userRequest setEntity:userEntity];
  NSError *error = nil;
  NSArray *fetchedResults = [[self.delegate getArangoManagedObjectContext] executeFetchRequest:userRequest error:&error];
  [userRequest release];
  if (fetchedResults == nil) {
    NSLog(error.localizedDescription);
  } else {
    if (fetchedResults.count > 0) {
      for (User* u in fetchedResults) {
        switch ([u.runOnStartUp intValue]) {
          case 0:
            [self.rosDefinition selectItemWithObjectValue:NON];
            break;
          case 1:
            [self.rosDefinition selectItemWithObjectValue:RES];
            break;
          case 2:
            [self.rosDefinition selectItemWithObjectValue:DEF];
            break;
          case 3:
            [self.rosDefinition selectItemWithObjectValue:ALL];
            break;
        }
      }
    } else {
      [self.rosDefinition selectItemWithObjectValue:RES];
    }
  }
  LSSharedFileListRef autostart = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil);
  if (autostart) {
    UInt32 seedValue;
    NSArray  *loginItemsArray = (NSArray *) LSSharedFileListCopySnapshot(autostart, &seedValue);
    for(int i = 0; i< [loginItemsArray count]; i++){
      LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef) [loginItemsArray objectAtIndex:i];
      CFURLRef url = (CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
      if (LSSharedFileListItemResolve(itemRef, 0, &url, nil) == noErr) {
        NSString * urlPath = [(NSURL*)url path];
        if ([urlPath compare:[[NSBundle mainBundle] bundlePath]] == NSOrderedSame){
          self.putAsStartUp.state = NSOnState;
        }
      }
    }
    [loginItemsArray release];
  }
}


- (IBAction) abort: (id) sender
{
  [self.window orderOut:self.window];
}


- (IBAction) store: (id) sender
{
  NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *userEntity = [NSEntityDescription entityForName:@"User" inManagedObjectContext: [self.delegate getArangoManagedObjectContext]];
  [userRequest setEntity:userEntity];
  NSError *error = nil;
  NSArray *fetchedResults = [[self.delegate getArangoManagedObjectContext] executeFetchRequest:userRequest error:&error];
  [userRequest release];
  NSNumber* ros = [NSNumber numberWithInt:0];
  if([self.rosDefinition.stringValue isEqual:RES]) {
    ros = [NSNumber numberWithInt:1];
  } else if([self.rosDefinition.stringValue isEqual:DEF]) {
    ros = [NSNumber numberWithInt:2];
  } else if([self.rosDefinition.stringValue isEqual:ALL]) {
    ros = [NSNumber numberWithInt:3];
  } else if([self.rosDefinition.stringValue isEqual:NON]) {
    ros = [NSNumber numberWithInt:0];
  }
  if (fetchedResults == nil) {
    NSLog(error.localizedDescription);
  } else {
    if (fetchedResults.count > 0) {
      for (User* u in fetchedResults) {
        u.runOnStartUp = ros;
      }
      [self.delegate save];
    } else {
      User* u = (User*) [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[self.delegate getArangoManagedObjectContext]];
      u.runOnStartUp = ros;
      [self.delegate save];
    }
  }
  LSSharedFileListRef autostart = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems, nil);
  if (autostart) {
    if (self.putAsStartUp.state == NSOnState) {
      LSSharedFileListItemRef arangoStarter = LSSharedFileListInsertItemURL(autostart, kLSSharedFileListItemLast, nil, nil, (CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]], nil, nil);
      if (arangoStarter) {
        CFRelease(arangoStarter);
      }
      CFRelease(autostart);
    } else {
      UInt32 seedValue;
      NSArray  *loginItemsArray = (NSArray *) LSSharedFileListCopySnapshot(autostart, &seedValue);
      for(int i = 0; i< [loginItemsArray count]; i++){
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef) [loginItemsArray objectAtIndex:i];
        CFURLRef url = (CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        if (LSSharedFileListItemResolve(itemRef, 0, &url, nil) == noErr) {
          NSString * urlPath = [(NSURL*)url path];
          if ([urlPath compare:[[NSBundle mainBundle] bundlePath]] == NSOrderedSame){
            LSSharedFileListItemRemove(autostart,itemRef);
          }
        }
      }
      [loginItemsArray release];
    }
  }
  
  [self.window orderOut:self.window];
}

@end
