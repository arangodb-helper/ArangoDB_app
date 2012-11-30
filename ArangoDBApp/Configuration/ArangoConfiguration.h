//
//  ArangoConfiguration.h
//  Arango
//
//  Created by Michael Hackstein on 21.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Bookmarks;

@interface ArangoConfiguration : NSManagedObject

@property (nonatomic, retain) NSNumber * isRunning;
@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSNumber * port;
@property (nonatomic, retain) NSNumber * runOnStartUp;
@property (nonatomic, retain) NSString * log;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * loglevel;
@property (nonatomic, retain) Bookmarks *bookmarks;
@property (nonatomic, retain) NSTask* instance;

@end
