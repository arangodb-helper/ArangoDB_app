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

#import "ArangoManager.h"
#import "User.h"

// -----------------------------------------------------------------------------
// --SECTION--                                        ArangoUserConfigController
// -----------------------------------------------------------------------------

@implementation ArangoUserConfigController

static const NSString* RES = @"Restart all instances running at last shutdown";
static const NSString* DEF = @"Define for each instance";
static const NSString* ALL = @"Start all instances";
static const NSString* NON = @"Do not start instances";

// -----------------------------------------------------------------------------
// --SECTION--                                                   private methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief aborts configuration dialog
////////////////////////////////////////////////////////////////////////////////

- (IBAction) abortConfiguration: (id) sender {
  [self.window close];
}

////////////////////////////////////////////////////////////////////////////////
/// @brief saves configuration
////////////////////////////////////////////////////////////////////////////////

- (IBAction) storeConfiguration: (id) sender {
  int ros = 0;

  if ([self.runOnStartupOptions.stringValue isEqual:RES]) {
    ros = 1;
  }
  else if ([self.runOnStartupOptions.stringValue isEqual:DEF]) {
    ros = 2;
  }
  else if ([self.runOnStartupOptions.stringValue isEqual:ALL]) {
    ros = 3;
  }
  else if([self.runOnStartupOptions.stringValue isEqual:NON]) {
    ros = 0;
  }

  [self.delegate setRunOnStartup:ros
               setStartupOnLogin:(self.startOnLoginButton.state == NSOnState)];

  [self.window close];
}

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief default constructor
////////////////////////////////////////////////////////////////////////////////

- (id) initWithArangoManager: (ArangoManager*) delegate {
  self = [super initWithArangoManager:delegate andNibNamed:@"ArangoUserConfigView" andReleasedWhenClose:YES];
  
  if (self) {
    switch ([self.delegate runOnStartup]) {
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
    
    self.startOnLoginButton.state = [self.delegate startupOnLogin] ? NSOnState : NSOffState;
  }
  
  return self;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief awakes from nib
////////////////////////////////////////////////////////////////////////////////

- (void) awakeFromNib {
  [self.runOnStartupOptions addItemWithObjectValue:RES];
  [self.runOnStartupOptions addItemWithObjectValue:DEF];
  [self.runOnStartupOptions addItemWithObjectValue:ALL];
  [self.runOnStartupOptions addItemWithObjectValue:NON];
}

@end

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// {@inheritDoc}\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\)"
// End:
