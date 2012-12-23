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

@property (nonatomic, strong) NSData * path;
@property (nonatomic, strong) NSData * log;
@property (nonatomic, strong) ArangoConfiguration *config;

@end
