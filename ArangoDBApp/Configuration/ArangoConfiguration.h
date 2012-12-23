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

@property (nonatomic, strong) NSNumber * isRunning;
@property (nonatomic, strong) NSString * alias;
@property (nonatomic, strong) NSNumber * port;
@property (nonatomic, strong) NSNumber * runOnStartUp;
@property (nonatomic, strong) NSString * log;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * loglevel;
@property (nonatomic, strong) Bookmarks *bookmarks;

@end
