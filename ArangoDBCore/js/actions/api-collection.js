/*jslint indent: 2, nomen: true, maxlen: 150, sloppy: true, vars: true, white: true, plusplus: true, stupid: true */
/*global require */

////////////////////////////////////////////////////////////////////////////////
/// @brief querying and managing collections
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2012 triagens GmbH, Cologne, Germany
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
/// @author Achim Brandt
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

var arangodb = require("org/arangodb");
var actions = require("org/arangodb/actions");

var API = "_api/collection";

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoAPI
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief collection representation
////////////////////////////////////////////////////////////////////////////////

function collectionRepresentation (collection, showProperties, showCount, showFigures) {
  var result = {};

  result.id = collection._id;
  result.name = collection.name();

  if (showProperties) {
    var properties = collection.properties();

    result.isVolatile    = properties.isVolatile;
    result.isSystem      = properties.isSystem;
    result.journalSize   = properties.journalSize;      
    result.keyOptions    = properties.keyOptions;
    result.waitForSync   = properties.waitForSync;
  }

  if (showCount) {
    result.count = collection.count();
  }

  if (showFigures) {
    var figures = collection.figures();

    if (figures) {
      result.figures = figures;
    }
  }

  result.status = collection.status();
  result.type = collection.type();

  return result;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoAPI
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief creates a collection
///
/// @RESTHEADER{POST /_api/collection,creates a collection}
///
/// @RESTDESCRIPTION
/// Creates an new collection with a given name. The request must contain an
/// object with the following attributes.
///
/// - `name`: The name of the collection.
///
/// - `waitForSync` (optional, default: false): If `true` then
///   the data is synchronised to disk before returning from a create or
///   update of an document.
///
/// - `journalSize` (optional, default is a @ref
///   CommandLineArangod "configuration parameter"): The maximal size of
///   a journal or datafile.  Note that this also limits the maximal
///   size of a single object. Must be at least 1MB.
///
/// - `isSystem` (optional, default is `false`): If `true`, create a
///   system collection. In this case `collection-name` should start with
///   an underscore. End users should normally create non-system collections
///   only. API implementors may be required to create system collections in
///   very special occasions, but normally a regular collection will do.
///
/// - `isVolatile` (optional, default is `false`): If `true` then the
///   collection data is kept in-memory only and not made persistent. Unloading
///   the collection will cause the collection data to be discarded. Stopping
///   or re-starting the server will also cause full loss of data in the
///   collection. Setting this option will make the resulting collection be 
///   slightly faster than regular collections because ArangoDB does not
///   enforce any synchronisation to disk and does not calculate any CRC 
///   checksums for datafiles (as there are no datafiles).
///
///   This option should threrefore be used for cache-type collections only, 
///   and not for data that cannot be re-created otherwise.
///
/// - `keyOptions` (optional) additional options for key generation. If
///   specified, then `keyOptions` should be a JSON array containing the
///   following attributes (note: some of them are optional):
///   - `type`: specifies the type of the key generator. The currently 
///     available generators are `traditional` and `autoincrement`.
///   - `allowUserKeys`: if set to `true`, then it is allowed to supply
///     own key values in the `_key` attribute of a document. If set to 
///     `false`, then the key generator will solely be responsible for
///     generating keys and supplying own key values in the `_key` attribute
///     of documents is considered an error.
///   - `increment`: increment value for `autoincrement` key generator.
///     Not used for other key generator types.
///   - `offset`: initial offset value for `autoincrement` key generator.
///     Not used for other key generator types.
///
/// - `type` (optional, default is `2`): the type of the collection to
///   create. The following values for `type` are valid:
///   - `2`: document collection
///   - `3`: edges collection
///
/// @EXAMPLES
///
/// @verbinclude api-collection-create-collection
///
/// @verbinclude api-collection-create-keyopt
////////////////////////////////////////////////////////////////////////////////

function post_api_collection (req, res) {
  var body = actions.getJsonBody(req, res);

  if (body === undefined) {
    return;
  }

  if (! body.hasOwnProperty("name")) {
    actions.resultBad(req, res, arangodb.ERROR_ARANGO_ILLEGAL_NAME,
                      "name must be non-empty");
    return;
  }

  var name = body.name;
  var parameter = { waitForSync : false };
  var type = arangodb.ArangoCollection.TYPE_DOCUMENT;
  var cid;

  if (body.hasOwnProperty("waitForSync")) {
    parameter.waitForSync = body.waitForSync;
  }

  if (body.hasOwnProperty("journalSize")) {
    parameter.journalSize = body.journalSize;
  }

  if (body.hasOwnProperty("isSystem")) {
    parameter.isSystem = body.isSystem;
  }
  
  if (body.hasOwnProperty("isVolatile")) {
    parameter.isVolatile = body.isVolatile;
  }

  if (body.hasOwnProperty("_id")) {
    cid = body._id;
  }

  if (body.hasOwnProperty("type")) {
    type = body.type;
  }
  
  if (body.hasOwnProperty("keyOptions")) {
    parameter.keyOptions = body.keyOptions;
  }

  try {
    var collection;
    if (typeof(type) === "string") {
      if (type.toLowerCase() === "edge") {
        type = arangodb.ArangoCollection.TYPE_EDGE;
      }
    }
    if (type === arangodb.ArangoCollection.TYPE_EDGE) {
      collection = arangodb.db._createEdgeCollection(name, parameter);
    }
    else {
      collection = arangodb.db._createDocumentCollection(name, parameter);
    }

    var result = {};
    var headers = {};

    result.id = collection._id;
    result.name = collection.name();
    result.waitForSync = parameter.waitForSync || false;
    result.isVolatile = parameter.isVolatile || false;
    result.isSystem = parameter.isSystem || false;
    result.status = collection.status();
    result.type = collection.type();
    result.keyOptions = collection.keyOptions;
    
    headers.location = "/" + API + "/" + result.name;

    actions.resultOk(req, res, actions.HTTP_OK, result, headers);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns all collections
///
/// @RESTHEADER{GET /_api/collection,reads all collections}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{excludeSystem,boolean,optional}
///
/// @RESTDESCRIPTION
/// Returns an object with an attribute `collections` containing a 
/// list of all collection descriptions. The same information is also
/// available in the `names` as hash map with the collection names
/// as keys.
///
/// By providing the optional URL parameter `excludeSystem` with a value of
/// `true`, all system collections will be excluded from the response.
///
/// @EXAMPLES
///
/// Return information about all collections:
///
/// @verbinclude api-collection-all-collections
////////////////////////////////////////////////////////////////////////////////

function get_api_collections (req, res) {
  var i;
  var list = [];
  var names = {};
  var excludeSystem;
  var collections = arangodb.db._collections();

  excludeSystem = false;
  if (req.parameters.hasOwnProperty('excludeSystem')) {
    var value = req.parameters.excludeSystem;
    if (value === 'true' || value === 'yes' || value === 'on' || value === 'y' || value === '1') {
      excludeSystem = true;
    }
  }

  for (i = 0;  i < collections.length;  ++i) {
    var collection = collections[i];
    var rep = collectionRepresentation(collection);

    // include system collections or exclude them?
    if (! excludeSystem || rep.name.substr(0, 1) !== '_') {
      list.push(rep);
      names[rep.name] = rep;
    }
  }

  var result = { collections : list, names : names };

  actions.resultOk(req, res, actions.HTTP_OK, result);
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns a collection
///
/// @RESTHEADER{GET /_api/collection/{collection-name},reads a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
/// 
/// @RESTDESCRIPTION
/// The result is an object describing the collection with the following
/// attributes:
///
/// - `id`: The identifier of the collection.
///
/// - `name`: The name of the collection.
///
/// - `status`: The status of the collection as number.
///  - 1: new born collection
///  - 2: unloaded
///  - 3: loaded
///  - 4: in the process of being unloaded
///  - 5: deleted
///
/// Every other status indicates a corrupted collection.
///
/// - `type`: The type of the collection as number.
///   - 2: document collection (normal case)
///   - 3: edges collection
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404` is
/// returned.
///
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
///
/// @RESTHEADER{GET /_api/collection/{collection-name}/properties,reads a collection with properties}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// In addition to the above, the result will always contain the
/// `waitForSync`, `journalSize`, and `isVolatile` properties. 
/// This is achieved by forcing a load of the underlying collection.
///
/// - `waitForSync`: If `true` then creating or changing a
///   document will wait until the data has been synchronised to disk.
///
/// - `journalSize`: The maximal size of a journal / datafile.
///
/// - `isVolatile`: If `true` then the collection data will be
///   kept in memory only and ArangoDB will not write or sync the data
///   to disk.
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404`
/// is returned.
///
/// @EXAMPLES
///
/// Using an identifier:
///
/// @verbinclude api-collection-get-collection-identifier
///
/// Using a name:
///
/// @verbinclude api-collection-get-collection-name
///
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
///
/// @RESTHEADER{GET /_api/collection/{collection-name}/count,reads a collection with count}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// In addition to the above, the result also contains the number of documents.
/// Note that this will always load the collection into memory.
///
/// - `count`: The number of documents inside the collection.
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404`
/// is returned.
///
/// @EXAMPLES
///
/// Using an identifier and requesting the number of documents:
///
/// @verbinclude api-collection-get-collection-count
///
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
///
/// @RESTHEADER{GET /_api/collection/{collection-name}/figures,reads a collection with stats}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// In addition to the above, the result also contains the number of documents
/// and additional statistical information about the collection.  Note that this
/// will always load the collection into memory.
///
/// - `count`: The number of documents inside the collection.
///
/// - `figures.alive.count`: The number of living documents.
///
/// - `figures.alive.size`: The total size in bytes used by all
///   living documents.
///
/// - `figures.dead.count`: The number of dead documents.
///
/// - `figures.dead.size`: The total size in bytes used by all
///   dead documents.
///
/// - `figures.dead.deletion`: The total number of deletion markers.
///
/// - `figures.datafiles.count`: The number of active datafiles.
/// - `figures.datafiles.fileSize`: The total filesize of datafiles.
///
/// - `figures.journals.count`: The number of journal files.
/// - `figures.journals.fileSize`: The total filesize of journal files.
///
/// - `figures.shapes.count`: The total number of shapes used in the 
///   collection (this includes shapes that are not in use anymore) 
///
/// - `figures.attributes.count`: The total number of attributes used 
///   in the collection (this includes attributes that are not in use anymore) 
///
/// - `journalSize`: The maximal size of the journal in bytes.
///
/// Note: the filesizes of shapes and compactor files are not reported.
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404`
/// is returned.
///
/// @EXAMPLES
///
/// Using an identifier and requesting the figures of the collection:
///
/// @verbinclude api-collection-get-collection-figures
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///
/// @RESTHEADER{GET /_api/collection/{collection-name}/revision, reads a collection with revision id}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// In addition to the above, the result will also contain the
/// collection's revision id. The revision id is a server-generated
/// string that clients can use to check whether data in a collection
/// has changed since the last revision check.
///
/// - `revision`: The collection revision id as a string.
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404`
/// is returned.
///
////////////////////////////////////////////////////////////////////////////////

function get_api_collection (req, res) {
  var name;
  var result;
  var sub;

  // .............................................................................
  // /_api/collection
  // .............................................................................
    
  if (req.suffix.length === 0 && req.parameters.id === undefined) {
    get_api_collections(req, res);
    return;
  }
    
  // .............................................................................
  // /_api/collection/<name>
  // .............................................................................

  name = decodeURIComponent(req.suffix[0]);
    
  var collection = arangodb.db._collection(name);

  if (collection === null) {
    actions.collectionNotFound(req, res, name);
    return;
  }
      
  var headers;

  // .............................................................................
  // /_api/collection/<name>
  // .............................................................................

  if (req.suffix.length === 1) {
    result = collectionRepresentation(collection, false, false, false);
    headers = { location : "/" + API + "/" + collection.name() };
    actions.resultOk(req, res, actions.HTTP_OK, result, headers);
    return;
  }

  if (req.suffix.length === 2) {
    sub = decodeURIComponent(req.suffix[1]);

    // .............................................................................
    // /_api/collection/<identifier>/figures
    // .............................................................................

    if (sub === "figures") {
      result = collectionRepresentation(collection, true, true, true);
      headers = { location : "/" + API + "/" + collection.name() + "/figures" };
      actions.resultOk(req, res, actions.HTTP_OK, result, headers);
    }

    // .............................................................................
    // /_api/collection/<identifier>/count
    // .............................................................................

    else if (sub === "count") {
      result = collectionRepresentation(collection, true, true, false);
      headers = { location : "/" + API + "/" + collection.name() + "/count" };
      actions.resultOk(req, res, actions.HTTP_OK, result, headers);
    }

    // .............................................................................
    // /_api/collection/<identifier>/properties
    // .............................................................................

    else if (sub === "properties") {
      result = collectionRepresentation(collection, true, false, false);
      headers = { location : "/" + API + "/" + collection.name() + "/properties" };
      actions.resultOk(req, res, actions.HTTP_OK, result, headers);
    }

    // .............................................................................
    // /_api/collection/<identifier>/parameter (DEPRECATED)
    // .............................................................................

    else if (sub === "parameter") {
      result = collectionRepresentation(collection, true, false, false);
      headers = { location : "/" + API + "/" + collection.name() + "/parameter" };
      actions.resultOk(req, res, actions.HTTP_OK, result, headers);
    }
    
    // .............................................................................
    // /_api/collection/<identifier>/revision
    // .............................................................................

    else if (sub === "revision") {
      result = collectionRepresentation(collection, false, false, false);
      result.revision = collection.revision();
      actions.resultOk(req, res, actions.HTTP_OK, result);
    }

    else {
      actions.resultNotFound(req, res, actions.ERROR_HTTP_NOT_FOUND,
                             "expecting one of the resources 'count',"
                             +" 'figures', 'properties', 'parameter'");
    }
  }
  else {
    actions.resultBad(req, res, actions.ERROR_HTTP_BAD_PARAMETER,
                      "expect GET /" + API + "/<collection-name>/<method>");
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief loads a collection
///
/// @RESTHEADER{PUT /_api/collection/{collection-name}/load,loads a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Loads a collection into memory. Returns the collection on success.
///
/// The request might optionally contain the following attribute:
///
/// - `count`: If set, this controls whether the return value should include
///   the number of documents in the collection. Setting `count` to 
///   `false` may speed up loading a collection. The default value for 
///   `count` is `true`.
///
/// On success an object with the following attributes is returned:
///
/// - `id`: The identifier of the collection.
///
/// - `name`: The name of the collection.
///
/// - `count`: The number of documents inside the collection. This is only
///   returned if the `count` input parameters is set to `true` or has
///   not been specified.
///
/// - `status`: The status of the collection as number.
///
/// - `type`: The collection type. Valid types are:
///   - 2: document collection
///   - 3: edges collection
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404`
/// is returned.
///
/// @EXAMPLES
///
/// @verbinclude api-collection-identifier-load
////////////////////////////////////////////////////////////////////////////////

function put_api_collection_load (req, res, collection) {
  try {
    collection.load();

    var showCount = true;
    var body = actions.getJsonBody(req, res);

    if (body && body.hasOwnProperty("count")) {
      showCount = body.count;
    }

    var result = collectionRepresentation(collection, false, showCount, false);

    actions.resultOk(req, res, actions.HTTP_OK, result);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief unloads a collection
///
/// @RESTHEADER{PUT /_api/collection/{collection-name}/unload,unloads a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Removes a collection from memory. This call does not delete any documents.
/// You can use the collection afterwards; in which case it will be loaded into
/// memory, again. On success an object with the following attributes is
/// returned:
///
/// - `id`: The identifier of the collection.
///
/// - `name`: The name of the collection.
///
/// - `status`: The status of the collection as number.
///
/// - `type`: The collection type. Valid types are:
///   - 2: document collection
///   - 3: edges collection
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404` is returned.
///
/// @EXAMPLES
///
/// @verbinclude api-collection-identifier-unload
////////////////////////////////////////////////////////////////////////////////

function put_api_collection_unload (req, res, collection) {
  try {
    collection.unload();

    var result = collectionRepresentation(collection);

    actions.resultOk(req, res, actions.HTTP_OK, result);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief truncates a collection
///
/// @RESTHEADER{PUT /_api/collection/{collection-name}/truncate,truncates a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Removes all documents from the collection, but leaves the indexes intact.
///
/// @EXAMPLES
///
/// @verbinclude api-collection-identifier-truncate
////////////////////////////////////////////////////////////////////////////////

function put_api_collection_truncate (req, res, collection) {
  try {
    collection.truncate();

    var result = collectionRepresentation(collection);

    actions.resultOk(req, res, actions.HTTP_OK, result);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief changes a collection
///
/// @RESTHEADER{PUT /_api/collection/{collection-name}/properties,changes the properties of a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Changes the properties of a collection. Expects an object with the
/// attribute(s)
///
/// - `waitForSync`: If `true` then creating or changing a
///   document will wait until the data has been synchronised to disk.
///
/// - `journalSize`: Size (in bytes) for new journal files that are
///   created for the collection.
///
/// If returns an object with the attributes
///
/// - `id`: The identifier of the collection.
///
/// - `name`: The name of the collection.
///
/// - `waitForSync`: The new value.
///
/// - `journalSize`: The new value.
///
/// - `status`: The status of the collection as number.
///
/// - `type`: The collection type. Valid types are:
///   - 2: document collection
///   - 3: edges collection
///
/// Note: some other collection properties, such as `type` or `isVolatile` 
/// cannot be changed once the collection is created.
///
/// @EXAMPLES
///
/// @verbinclude api-collection-identifier-properties-sync
////////////////////////////////////////////////////////////////////////////////

function put_api_collection_properties (req, res, collection) {
  var body = actions.getJsonBody(req, res);

  if (body === undefined) {
    return;
  }

  try {
    collection.properties(body);

    var result = collectionRepresentation(collection, true);

    actions.resultOk(req, res, actions.HTTP_OK, result);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief renames a collection
///
/// @RESTHEADER{PUT /_api/collection/{collection-name}/rename,renames a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Renames a collection. Expects an object with the attribute(s)
///
/// - `name`: The new name.
///
/// If returns an object with the attributes
///
/// - `id`: The identifier of the collection.
///
/// - `name`: The new name of the collection.
///
/// - `status`: The status of the collection as number.
///
/// - `type`: The collection type. Valid types are:
///   - 2: document collection
///   - 3: edges collection
///
/// @EXAMPLES
///
/// @verbinclude api-collection-identifier-rename
////////////////////////////////////////////////////////////////////////////////

function put_api_collection_rename (req, res, collection) {
  var body = actions.getJsonBody(req, res);

  if (body === undefined) {
    return;
  }

  if (! body.hasOwnProperty("name")) {
    actions.resultBad(req, res, arangodb.ERROR_ARANGO_ILLEGAL_NAME,
                      "name must be non-empty");
    return;
  }

  var name = body.name;

  try {
    collection.rename(name);

    var result = collectionRepresentation(collection);

    actions.resultOk(req, res, actions.HTTP_OK, result);
  }
  catch (err) {
    actions.resultException(req, res, err);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief changes a collection
////////////////////////////////////////////////////////////////////////////////

function put_api_collection (req, res) {
  if (req.suffix.length !== 2) {
    actions.resultBad(req, res, actions.ERROR_HTTP_BAD_PARAMETER,
                      "expected PUT /" + API + "/<collection-name>/<action>");
    return;
  }

  var name = decodeURIComponent(req.suffix[0]);
  var collection = arangodb.db._collection(name);

  if (collection === null) {
    actions.collectionNotFound(req, res, name);
    return;
  }

  var sub = decodeURIComponent(req.suffix[1]);

  if (sub === "load") {
    put_api_collection_load(req, res, collection);
  }
  else if (sub === "unload") {
    put_api_collection_unload(req, res, collection);
  }
  else if (sub === "truncate") {
    put_api_collection_truncate(req, res, collection);
  }
  else if (sub === "properties") {
    put_api_collection_properties(req, res, collection);
  }
  else if (sub === "rename") {
    put_api_collection_rename(req, res, collection);
  }
  else {
    actions.resultNotFound(req, res, actions.errors.ERROR_HTTP_NOT_FOUND,
                           "expecting one of the actions 'load', 'unload',"
                           + " 'truncate', 'properties', 'rename'");
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief deletes a collection
///
/// @RESTHEADER{DELETE /_api/collection/{collection-name},deletes a collection}
///
/// @RESTURLPARAMETERS
///
/// @RESTURLPARAM{collection-name,string,required}
///
/// @RESTDESCRIPTION
/// Deletes a collection identified by `collection-name`.
///
/// If the collection was successfully deleted then, an object is returned with
/// the following attributes:
///
/// - `error`: `false`
///
/// - `id`: The identifier of the deleted collection.
///
/// @RESTRETURNCODES
///
/// @RESTRETURNCODE{400}
/// If the `collection-name` is missing, then a `HTTP 400` is
/// returned.
///
/// @RESTRETURNCODE{404}
/// If the `collection-name` is unknown, then a `HTTP 404` is returned.
///
/// @EXAMPLES
///
/// Using an identifier:
///
/// @verbinclude api-collection-delete-collection-identifier
///
/// Using a name:
///
/// @verbinclude api-collection-delete-collection-name
////////////////////////////////////////////////////////////////////////////////

function delete_api_collection (req, res) {
  if (req.suffix.length !== 1) {
    actions.resultBad(req, res, actions.ERROR_HTTP_BAD_PARAMETER,
                      "expected DELETE /" + API + "/<collection-name>");
  }
  else {
    var name = decodeURIComponent(req.suffix[0]);
    var collection = arangodb.db._collection(name);

    if (collection === null) {
      actions.collectionNotFound(req, res, name);
    }
    else {
      try {
        var result = {
          id : collection._id
        };

        collection.drop();

        actions.resultOk(req, res, actions.HTTP_OK, result);
      }
      catch (err) {
        actions.resultException(req, res, err);
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief handles a collection request
////////////////////////////////////////////////////////////////////////////////

actions.defineHttp({
  url : API,
  context : "api",

  callback : function (req, res) {
    try {
      if (req.requestType === actions.GET) {
        get_api_collection(req, res);
      }
      else if (req.requestType === actions.DELETE) {
        delete_api_collection(req, res);
      }
      else if (req.requestType === actions.POST) {
        post_api_collection(req, res);
      }
      else if (req.requestType === actions.PUT) {
        put_api_collection(req, res);
      }
      else {
        actions.resultUnsupported(req, res);
      }
    }
    catch (err) {
      actions.resultException(req, res, err);
    }
  }
});

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @\\}"
// End:
