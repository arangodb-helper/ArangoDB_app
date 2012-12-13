  if ([config.isRunning isEqualToNumber:[NSNumber numberWithBool:YES]]) {
    [config.instance terminate];
  }
  if (deleteFiles) {
      [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(deleteFiles:) userInfo:config repeats:NO];
  } else {
    if (config.bookmarks != nil  && version > 106) {
      NSURL* oldPath = [self urlForBookmark:config.bookmarks.path];
      if (oldPath != nil) {
        [oldPath stopAccessingSecurityScopedResource];
      }
      NSURL* oldLogPath = [self urlForBookmark:config.bookmarks.log];
      if (oldLogPath != nil) {
        [oldLogPath stopAccessingSecurityScopedResource];
      }
      [[self getArangoManagedObjectContext] deleteObject: config.bookmarks];
      config.bookmarks = nil;
    }
    [[self getArangoManagedObjectContext] deleteObject: config];
    [self save];
    [statusMenu updateMenu];
  }
