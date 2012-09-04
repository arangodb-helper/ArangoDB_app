//
//  arangoCreateNewDBWindowController.h
//  Arango
//
//  Created by Michael Hackstein on 04.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface arangoCreateNewDBWindowController : NSWindowController
@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *dbPathField;
@property (weak) IBOutlet NSTextField *portField;
@property (weak) IBOutlet NSTextField *logField;
@property (weak) IBOutlet NSTextField *aliasField;

@end
