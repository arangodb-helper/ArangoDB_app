////////////////////////////////////////////////////////////////////////////////
/// @brief user configuration controller
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2012 triAGENS GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is triAGENS GmbH, Cologne, Germany
///
/// @author Dr. Frank Celler
/// @author Michael Hackstein
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

#import "ArangoUserConfigController.h"

#import "arangoAppDelegate.h"
#import "User.h"

// -----------------------------------------------------------------------------
// --SECTION--                                        ArangoUserConfigController
// -----------------------------------------------------------------------------

@implementation ArangoUserConfigController

static const NSString* RES = @"Restart all instances running at last shutdown";
static const NSString* DEF = @"Define for each instance";
static const NSString* ALL = @"Start all instances";
static const NSString* NON = @"Do not start instaces";

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) delegate {
  return [super initWithArangoManager:delegate];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief awakes from nib
////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib {
  [self.runOnStartupOptions addItemWithObjectValue:RES];
  [self.runOnStartupOptions addItemWithObjectValue:DEF];
  [self.runOnStartupOptions addItemWithObjectValue:ALL];
  [self.runOnStartupOptions addItemWithObjectValue:NON];

  switch ([_delegate.user.runOnStartUp intValue]) {
    case 0:
      [self.runOnStartupOptions selectItemWithObjectValue:NON];
      break;

    case 1:
      [self.runOnStartupOptions selectItemWithObjectValue:RES];
      break;

    case 2:
      [self.runOnStartupOptions selectItemWithObjectValue:DEF];
      break;

    case 3:
      [self.runOnStartupOptions selectItemWithObjectValue:ALL];
      break;
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
          self.runOnStartupButton.state = NSOnState;
        }
      }
    }
    [loginItemsArray release];
  }
}


- (IBAction) abortConfiguration: (id) sender
{
  [self.window orderOut:self.window];
}


- (IBAction) storeConfiguration: (id) sender
{
  NSFetchRequest *userRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *userEntity = [NSEntityDescription entityForName:@"User" inManagedObjectContext: [self.delegate getArangoManagedObjectContext]];
  [userRequest setEntity:userEntity];
  NSError *error = nil;
  NSArray *fetchedResults = [[self.delegate getArangoManagedObjectContext] executeFetchRequest:userRequest error:&error];
  [userRequest release];
  NSNumber* ros = [NSNumber numberWithInt:0];
  if([self.runOnStartupOptions.stringValue isEqual:RES]) {
    ros = [NSNumber numberWithInt:1];
  } else if([self.runOnStartupOptions.stringValue isEqual:DEF]) {
    ros = [NSNumber numberWithInt:2];
  } else if([self.runOnStartupOptions.stringValue isEqual:ALL]) {
    ros = [NSNumber numberWithInt:3];
  } else if([self.runOnStartupOptions.stringValue isEqual:NON]) {
    ros = [NSNumber numberWithInt:0];
  }
  if (fetchedResults == nil) {
    NSLog(@"%@", error.localizedDescription);
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
    if (self.runOnStartupButton.state == NSOnState) {
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
