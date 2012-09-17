//
//  arangoUserConfigController.h
//  Arango
//
//  Created by Michael Hackstein on 17.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class arangoAppDelegate;

@interface arangoUserConfigController : NSWindowController
@property (weak) IBOutlet NSButton *putAsStartUp;
@property (weak) IBOutlet NSComboBox *rosDefinition;
@property (weak) arangoAppDelegate* delegate;

- (id) initWithAppDelegate: (arangoAppDelegate*) aD;
- (IBAction) store: (id) sender;
- (IBAction) abort: (id) sender;

@end
