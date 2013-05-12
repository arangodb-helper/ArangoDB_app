/*jslint indent: 2, nomen: true, maxlen: 100, white: true, plusplus: true, unparam: true */
/*global foxxes*/
/*global require, applicationContext*/

////////////////////////////////////////////////////////////////////////////////
/// @brief A Foxx-Application to overview your Foxx-Applications
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2010-2013 triagens GmbH, Cologne, Germany
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
/// @author Michael Hackstein
/// @author Copyright 2011-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

(function() {
  "use strict";

  // Initialise a new FoxxApplication called app under the urlPrefix: "foxxes".
  var FoxxApplication = require("org/arangodb/foxx").Application,
    app = new FoxxApplication();
  
  app.registerRepository(
    "foxxes",
    {
      repository: "repositories/foxxes"
    }
  );
  
  app.registerRepository(
    "docus",
    {
      repository: "repositories/swagger"
    }
  );
  
  app.put("/foxxes/install", function (req, res) {
    var content = JSON.parse(req.requestBody),
      name = content.name,
      mount = content.mount,
      version = content.version;
      res.json(repositories.foxxes.install(name, mount, version));
  }).nickname("foxxinstall")
  .summary("Installs a new foxx")
  .notes("This function is used to install a new foxx.");
  
  
  app.del("/foxxes/:key", function (req, res) {
    res.json(repositories.foxxes.uninstall(req.params("key")));
  }).pathParam("key", {
    description: "The _key attribute, where the information of this Foxx-Install is stored.",
    dataType: "string",
    required: true,
    allowMultiple: false
  }).nickname("foxxes")
  .summary("Uninstall a Foxx.")
  .notes("This function is used to uninstall a foxx.");
  
  app.put("/foxxes/:key", function (req, res) {
    var content = JSON.parse(req.requestBody),
    active = content.active;
    // TODO: Other changes applied to foxx! e.g. Mount
    if (active) {
      res.json(repositories.foxxes.activate());
    } else {
      res.json(repositories.foxxes.deactivate());
    }
  }).pathParam("key", {
    description: "The _key attribute, where the information of this Foxx-Install is stored.",
    dataType: "string",
    required: true,
    allowMultiple: false
  }).nickname("foxxes")
  .summary("Update a foxx.")
  .notes("Used to either activate/deactivate a foxx, or change the mount point.");
  
  app.get("/foxxes/thumbnail/:app", function (req, res) {
    res.transformations = [ "base64decode" ];
    res.body = repositories.foxxes.thumbnail(req.params("app"));
  }).pathParam("app", {
    description: "The appname which is used to identify the foxx in the list of available foxxes.",
    dataType: "string",
    required: true,
    allowMultiple: false
  }).nickname("thumbnails")
  .summary("Get the thumbnail of a foxx.")
  .notes("Used to request the thumbnail of the given Foxx in order to display it on the screen.");
  
  
  app.get('/foxxes', function (req, res) {
    res.json(repositories.foxxes.viewAll());
  }).nickname("foxxes")
  .summary("List of all foxxes.")
  .notes("This function simply returns the list of all running foxxes");
  
  app.get('/docus', function (req, res) {
    res.json(repositories.docus.list("http://" + req.headers.host + req.path + "/"));
  }).nickname("swaggers")
  .summary("List documentation of all foxxes.")
  .notes("This function simply returns the list of all running"
   + " foxxes and supplies the paths for the swagger documentation");
  
   app.get("/docu/:key",function (req, res) {
     var subPath = req.path.substr(0,req.path.lastIndexOf("[")-1),
       key = req.params("key"),
       path = "http://" + req.headers.host + subPath + "/" + key + "/";
     res.json(repositories.docus.listOne(path, key));
  }).nickname("swaggers")
  .summary("List documentation of all foxxes.")
  .notes("This function simply returns one specific"
   + " foxx and supplies the paths for the swagger documentation");
  
  
  app.get('/docu/:key/*', function(req, res) {
    var mountPoint = "";
    require("underscore").each(req.suffix, function(part) {
      mountPoint += "/" + part;
    });
    res.json(repositories.docus.show(mountPoint))
  }).pathParam("appname", {
    description: "The mount point of the App the documentation should be requested for",
    dataType: "string",
    required: true,
    allowMultiple: false
  }).nickname("swaggersapp")
  .summary("List the API for one foxx")
  .notes("This function lists the API of the foxx"
    + " runnning under the given mount point");
  
  app.start(applicationContext);
}());