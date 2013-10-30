/*jslint indent: 2, nomen: true, maxlen: 120, sloppy: true, vars: true, white: true, plusplus: true, nonpropdel: true */
/*global require, db, ArangoCollection, ArangoDatabase, ArangoCursor,
         ShapedJson, RELOAD_AUTH, SYS_DEFINE_ACTION, SYS_EXECUTE_GLOBAL_CONTEXT_FUNCTION,
         AHUACATL_RUN, AHUACATL_PARSE, AHUACATL_EXPLAIN */

////////////////////////////////////////////////////////////////////////////////
/// @brief module "internal"
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2004-2013 triAGENS GmbH, Cologne, Germany
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
/// @author Copyright 2010-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 Module "internal"
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoShell
/// @{
////////////////////////////////////////////////////////////////////////////////

(function () {
  var internal = require("internal");
  var console = require("console");

////////////////////////////////////////////////////////////////////////////////
/// @brief hide global variables
////////////////////////////////////////////////////////////////////////////////

  internal.db = db;
  delete db;

  internal.ArangoCollection = ArangoCollection;
  delete ArangoCollection;

  internal.ArangoDatabase = ArangoDatabase;
  delete ArangoDatabase;

  internal.ArangoCursor = ArangoCursor;
  delete ArangoCursor;

  internal.ShapedJson = ShapedJson;
  delete ShapedJson;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private variables
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoShell
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief execute an AQL query
////////////////////////////////////////////////////////////////////////////////

  internal.AQL_QUERY = AHUACATL_RUN;
  delete AHUACATL_RUN;

////////////////////////////////////////////////////////////////////////////////
/// @brief parse an AQL query
////////////////////////////////////////////////////////////////////////////////

  internal.AQL_PARSE = AHUACATL_PARSE;
  delete AHUACATL_PARSE;

////////////////////////////////////////////////////////////////////////////////
/// @brief explain an AQL query
////////////////////////////////////////////////////////////////////////////////

  internal.AQL_EXPLAIN = AHUACATL_EXPLAIN;
  delete AHUACATL_EXPLAIN;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoShell
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief resets engine in development mode
////////////////////////////////////////////////////////////////////////////////

  internal.resetEngine = function () {
    internal.flushModuleCache();
    require("org/arangodb/actions").reloadRouting();
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief rebuilds the authentication cache
////////////////////////////////////////////////////////////////////////////////

  internal.reloadAuth = RELOAD_AUTH;
  delete RELOAD_AUTH;

////////////////////////////////////////////////////////////////////////////////
/// @brief defines an action
////////////////////////////////////////////////////////////////////////////////

  if (typeof SYS_DEFINE_ACTION === "undefined") {
    internal.defineAction = function() {
      console.error("SYS_DEFINE_ACTION not available");
    };

    internal.actionLoaded = function() {
    };
  }
  else {
    internal.defineAction = SYS_DEFINE_ACTION;
    delete SYS_DEFINE_ACTION;

    internal.actionLoaded = function() {
      var modules;
      var i;

      console.debug("actions loaded");
    };
  }

////////////////////////////////////////////////////////////////////////////////
/// @brief initialize foxx applications
////////////////////////////////////////////////////////////////////////////////

  internal.initializeFoxx = function () {
    var fm = require("org/arangodb/foxx/manager");

    try {
      fm.scanAppDirectory();
    }
    catch (err) {
      console.error("cannot initialize Foxx application: %s", String(err));
    }

    var aal = internal.db._collection("_aal");

    if (aal !== null) {
      var found = aal.firstExample({ type: "mount", mount: "/_admin/aardvark" });

      if (found === null) {
        fm.mount("aardvark", "/_admin/aardvark", {reload: false});
      }
    }
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief reloads the AQL user functions
////////////////////////////////////////////////////////////////////////////////

  if (typeof SYS_EXECUTE_GLOBAL_CONTEXT_FUNCTION === "undefined") {
    internal.reloadAqlFunctions = function () {
      require("org/arangodb/ahuacatl").reload();
    };
  }
  else {
    internal.reloadAqlFunctions = function () {
      internal.executeGlobalContextFunction("try { require(\"org/arangodb/ahuacatl\").reload(); } catch (err) { }");
      require("org/arangodb/ahuacatl").reload();
    };
  }

////////////////////////////////////////////////////////////////////////////////
/// @brief executes a string in all V8 contexts
////////////////////////////////////////////////////////////////////////////////

  if (typeof SYS_EXECUTE_GLOBAL_CONTEXT_FUNCTION === "undefined") {
    internal.executeGlobalContextFunction = function() {
      // nothing to do. we're probably in --console mode
    };
  }
  else {
    internal.executeGlobalContextFunction = SYS_EXECUTE_GLOBAL_CONTEXT_FUNCTION;
    delete SYS_EXECUTE_GLOBAL_CONTEXT_FUNCTION;
  }

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

}());

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\|/\\*jslint"
// End:
