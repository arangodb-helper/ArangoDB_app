////////////////////////////////////////////////////////////////////////////////
/// @brief version check at the start of the server, will optionally perform
/// necessary upgrades
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2004-2012 triAGENS GmbH, Cologne, Germany
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
/// @author Jan Steemann
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                     version check
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoDB
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief updates the database
////////////////////////////////////////////////////////////////////////////////

(function() {
  var internal = require("internal");
  var console = require("console");
  var db = internal.db;

  // path to the VERSION file
  var versionFile = DATABASEPATH + "/VERSION";

  function runUpgrade (currentVersion) {
    var allTasks = [ ];
    var activeTasks = [ ];
    var lastVersion = null;
    var lastTasks   = { };
  
    function getCollection (name) {
      return db._collection(name);
    }

    function collectionExists (name) {
      var collection = getCollection(name);
      return (collection != undefined) && (collection != null) && (collection.name() == name);
    }

    function createSystemCollection (name, attributes) {
      if (collectionExists(name)) {
        return true;
      }

      var realAttributes = attributes || { };
      realAttributes['isSystem'] = true;

      if (db._create(name, realAttributes)) {
        return true;
      }

      return collectionExists(name);
    }
  
    // helper function to define tasks
    function addTask (name, description, code) {
      // "description" is a textual description of the task that will be printed out on screen
      // "maxVersion" is the maximum version number the task will be applied for
      var task = { name: name, description: description, code: code };

      allTasks.push(task);

      if (lastTasks[name] === undefined || lastTasks[name] === false) {
        // task never executed or previous execution failed
        activeTasks.push(task);
      }
    }


    if (internal.exists(versionFile)) {
      // VERSION file exists, read its contents
      var versionInfo = internal.read(versionFile);

      if (versionInfo != '') {
        var versionValues = JSON.parse(versionInfo);

        if (versionValues && versionValues.version && ! isNaN(versionValues.version)) {
          lastVersion = parseFloat(versionValues.version);
        }

        if (versionValues && versionValues.tasks && typeof(versionValues.tasks) === 'object') {
          lastTasks   = versionValues.tasks || { };
        }
      }
    }
    
    console.log("Starting upgrade from version " + (lastVersion || "unknown") + " to " + VERSION);

    // --------------------------------------------------------------------------
    // the actual upgrade tasks. all tasks defined here should be "re-entrant"
    // --------------------------------------------------------------------------

    // set up the collection _users 
    addTask("setupUsers", "setup _users collection", function () {
      return createSystemCollection("_users", { waitForSync : true });
    });

    // create a unique index on username attribute in _users
    addTask("createUsersIndex", "create index on username attribute in _users collection", function () {
      var users = getCollection("_users");
      if (! users) {
        return false;
      }

      users.ensureUniqueConstraint("username");

      return true;
    });
  
    // add a default root user with no passwd
    addTask("addDefaultUser", "add default root user", function () {
      var users = getCollection("_users");
      if (! users) {
        return false;
      }

      if (users.count() == 0) {
        // only add account if user has not created his/her own accounts already
        users.save({ user: "root", password: internal.encodePassword(""), active: true });
      }

      return true;
    });
  
    // set up the collection _graphs
    addTask("setupGraphs", "setup _graphs collection", function () {
      return createSystemCollection("_graphs", { waitForSync : true });
    });
  
    // create a unique index on name attribute in _graphs
    addTask("createGraphsIndex", "create index on name attribute in _graphs collection", function () {
      var graphs = getCollection("_graphs");

      if (! graphs) {
        return false;
      }

      graphs.ensureUniqueConstraint("name");

      return true;
    });

    // make distinction between document and edge collections
    addTask("addCollectionVersion", "set new collection type for edge collections and update collection version", function () {
      var collections = db._collections();
      
      for (var i in collections) {
        var collection = collections[i];

        try {
          if (collection.version() > 1) {
            // already upgraded
            continue;
          }

          if (collection.type() == 3) {
            // already an edge collection
            collection.setAttribute("version", 2);
            continue;
          }
        
          if (collection.count() > 0) {
            var isEdge = true;
            // check the 1st 50 documents from a collection
            var documents = collection.ALL(0, 50);

            for (var j in documents) {
              var doc = documents[j];
    
              // check if documents contain both _from and _to attributes
              if (! doc.hasOwnProperty("_from") || ! doc.hasOwnProperty("_to")) {
                isEdge = false;
                break;
              }
            }

            if (isEdge) {
              collection.setAttribute("type", 3);
              console.log("made collection '" + collection.name() + " an edge collection");
            }
          }
          collection.setAttribute("version", 2);
        }
        catch (e) {
          console.error("could not upgrade collection '" + collection.name() + "'");
          return false;
        }
      }

      return true;
    });
    
    // create the _modules collection
    addTask("createModules", "setup _modules collection", function () {
      return createSystemCollection("_modules");
    });
    
    // create the _routing collection
    addTask("createRouting", "setup _routing collection", function () {
      return createSystemCollection("_routing");
    });
    
    // create the default route in the _routing collection
    addTask("insertDefaultRoute", "insert default route for the admin interface", function () {
      var routing = getCollection("_routing");

      if (! routing) {
        return false;
      }

      if (routing.count() == 0) {
        // only add route if no other route has been defined
        routing.save({ url: "/", action: { "do": "org/arangodb/actions/redirectRequest", options: { permanently: true, destination: "/_admin/html/index.html" } } });
      }

      return true;
    });
    
    // set up the collection _structures
    addTask("setupStructures", "setup _structures collection", function () {
      return createSystemCollection("_structures", { waitForSync : true });
    });
  
    // create a unique index on collection attribute in _structures
    addTask("createStructuresIndex", "create index on collection attribute in _structures collection", function () {
      var structures = getCollection("_structures");

      if (! structures) {
        return false;
      }

      structures.ensureUniqueConstraint("collection");

      return true;
    });

    // loop through all tasks and execute them
    console.log("Found " + allTasks.length + " defined task(s), " + activeTasks.length + " task(s) to run");

    var taskNumber = 0;
    for (var i in activeTasks) {
      var task = activeTasks[i];

      console.log("Executing task #" + (++taskNumber) + " (" + task.name + "): " + task.description);

      // assume failure
      var result = false;
      try {
        // execute task
        result = task.code();
      }
      catch (e) {
      }

      if (result) {
        // success
        lastTasks[task.name] = true;
        // save/update version info
        SYS_SAVE(versionFile, JSON.stringify({ version: currentVersion, tasks: lastTasks }));
        console.log("Task successful");
      }
      else {
        console.error("Task failed. Aborting upgrade procedure.");
        console.error("Please fix the problem and try starting the server again.");
        return false;
      }
    }

    // save file so version gets saved even if there are no tasks
    SYS_SAVE(versionFile, JSON.stringify({ version: currentVersion, tasks: lastTasks }));

    console.log("Upgrade successfully finished");

    return true;
  }



  var lastVersion = null;
  var currentServerVersion = VERSION.match(/^(\d+\.\d+).*$/);
  if (! currentServerVersion) {
    // server version is invalid for some reason
    console.error("Unexpected ArangoDB server version: " + VERSION);
    return false;
  }
  
  var currentVersion = parseFloat(currentServerVersion[1]);
  
  if (! internal.exists(versionFile)) {
    console.info("No version information file found in database directory.");
    return runUpgrade(currentVersion);
  }

   // VERSION file exists, read its contents
  var versionInfo = internal.read(versionFile);
  if (versionInfo != '') {
    var versionValues = JSON.parse(versionInfo);
    if (versionValues && versionValues.version && ! isNaN(versionValues.version)) {
      lastVersion = parseFloat(versionValues.version);
    }
  }
  
  if (lastVersion == null) {
    console.info("No VERSION file found in database directory.");
    return runUpgrade(currentVersion);
  }

  if (lastVersion == currentVersion) {
    // version match!
    return true;
  }

  if (lastVersion > currentVersion) {
    // downgrade??
    console.error("Database directory version (" + lastVersion + ") is higher than server version (" + currentVersion + ").");
    console.error("It seems like you are running ArangoDB on a database directory that was created with a newer version of ArangoDB. Maybe this is what you wanted but it is not supported by ArangoDB.");
    // still, allow the start
    return true;
  }
  else if (lastVersion < currentVersion) {
    // upgrade
    if (UPGRADE) {
      return runUpgrade(currentVersion);
    }

    console.error("Database directory version (" + lastVersion + ") is lower than server version (" + currentVersion + ").");
    console.error("It seems like you have upgraded the ArangoDB binary. If this is what you wanted to do, please restart with the --upgrade option to upgrade the data in the database directory.");
    // do not start unless started with --upgrade
    return false;
  }

  // we should never get here
  return true;
})();

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
