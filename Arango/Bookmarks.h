//
//  Bookmarks.h
//  Arango
//
//  Created by Michael Hackstein on 21.09.12.
//  Copyright (c) 2012 triAgens. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ArangoConfiguration;

@interface Bookmarks : NSManagedObject

@property (nonatomic, retain) NSData * path;
@property (nonatomic, retain) NSData * log;
@property (nonatomic, retain) ArangoConfiguration *config;

@end
