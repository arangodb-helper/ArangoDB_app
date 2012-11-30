module.define("simple-query-basics", function(exports, module) {
////////////////////////////////////////////////////////////////////////////////
/// @brief Arango Simple Query Language
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
/// @author Dr. Frank Celler
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

var internal = require("internal");
var ArangoCollection = internal.ArangoCollection;
var ArangoEdgesCollection = internal.ArangoEdgesCollection;

// -----------------------------------------------------------------------------
// --SECTION--                                              GENERAL ARRAY CURSOR
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup GeneralArrayCursor
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief array query
////////////////////////////////////////////////////////////////////////////////

function GeneralArrayCursor (documents, skip, limit) {
  this._documents = documents;
  this._countTotal = documents.length;
  this._skip = skip;
  this._limit = limit;

  this.execute();
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief executes an array query
////////////////////////////////////////////////////////////////////////////////

GeneralArrayCursor.prototype.execute = function () {
  if (this._skip === null) {
    this._skip = 0;
  }

  var len = this._documents.length;
  var s = 0;
  var e = len;

  // skip from the beginning
  if (0 < this._skip) {
    s = this._skip;

    if (e < s) {
      s = e;
    }
  }

  // skip from the end
  else if (this._skip < 0) {
    var skip = -this._skip;

    if (skip < e) {
      s = e - skip;
    }
  }

  // apply limit
  if (this._limit != null) {
    if (s + this._limit < e) {
      e = s + this._limit;
    }
  }

  this._current = s;
  this._stop = e;

  this._countQuery = e - s;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief print an all query
////////////////////////////////////////////////////////////////////////////////

GeneralArrayCursor.prototype._PRINT = function () {
  var text;

  text = "GeneralArrayCursor([.. " + this._documents.length + " docs ..])";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if the cursor is exhausted
////////////////////////////////////////////////////////////////////////////////

GeneralArrayCursor.prototype.hasNext = function () {
  return this._current < this._stop;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the next result document
////////////////////////////////////////////////////////////////////////////////

GeneralArrayCursor.prototype.next = function() {
  if (this._current < this._stop) {
    return this._documents[this._current++];
  }
  else {
    return undefined;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief drops the result
////////////////////////////////////////////////////////////////////////////////

GeneralArrayCursor.prototype.dispose = function() {
  this._documents = null;
  this._skip = null;
  this._limit = null;
  this._countTotal = null;
  this._countQuery = null;
  this.current = null;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                      SIMPLE QUERY
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief simple query
////////////////////////////////////////////////////////////////////////////////

function SimpleQuery () {
  this._execution = null;
  this._skip = 0;
  this._limit = null;
  this._countQuery = null;
  this._countTotal = null;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief join limits
////////////////////////////////////////////////////////////////////////////////

function JoinLimits (query, limit) {
  var q;

  // original limit is 0, keep it
  if (query._limit === 0) {
    query = query.clone();
  }

  // new limit is 0, use it
  else if (limit === 0) {
    query = query.clone();
    query._limit = 0;
  }

  // no old limit, use new limit
  else if (query._limit === null) {
    query = query.clone();
    query._limit = limit
  }

  // use the smaller one
  else {
    query = query.clone();

    if (limit < query._limit) {
      query._limit = limit;
    }
  }

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief clones a query
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.clone = function () {
  throw "cannot clone abstract query";
}

////////////////////////////////////////////////////////////////////////////////
/// @brief executes a query
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.execute = function () {
  throw "cannot execute abstract query";
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief limit
///
/// @FUN{@FA{query}.limit(@FA{number})}
///
/// Limits a result to the first @FA{number} documents. Specifying a limit of
/// @CODE{0} returns no documents at all. If you do not need a limit, just do
/// not add the limit operator. The limit must be non-negative.
///
/// In general the input to @FN{limit} should be sorted. Otherwise it will be
/// unclear which documents are used in the result set.
///
/// @EXAMPLES
/// 
/// @verbinclude simple2
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.limit = function (limit) {
  if (this._execution != null) {
    throw "query is already executing";
  }

  if (limit < 0) {
    var err = new ArangoError();
    err.errorNum = internal.errors.ERROR_BAD_PARAMETER;
    err.errorMessage = "limit must be non-negative";
    throw err;
  }

  return JoinLimits(this, limit);
}

////////////////////////////////////////////////////////////////////////////////
/// @brief skip
///
/// @FUN{@FA{query}.skip(@FA{number})}
///
/// Skips the first @FA{number} documents. If @FA{number} is positive, then skip
/// the number of documents. If @FA{number} is negative, then the total amount N
/// of documents must be known and the results starts at position (N +
/// @FA{number}).
///
/// In general the input to @FN{limit} should be sorted. Otherwise it will be
/// unclear which documents are used in the result set.
///
/// @EXAMPLES
///
/// @verbinclude simple8
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.skip = function (skip) {
  var query;
  var documents;

  if (skip === undefined || skip === null) {
    skip = 0;
  }

  if (this._execution != null) {
    throw "query is already executing";
  }

  // no limit set, use or add skip
  if (this._limit === null) {
    query = this.clone();

    if (this._skip === null || this._skip === 0) {
      query._skip = skip;
    }
    else {
      query._skip += skip;
    }
  }

  // limit already set
  else {
    documents = this.clone().toArray();

    query = new SimpleQueryArray(documents);
    query._skip = skip;
    query._countTotal = documents._countTotal;
  }

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief converts into an array
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.toArray = function () {
  var cursor;
  var result;

  this.execute();

  result = [];

  while (this.hasNext()) {
    result.push(this.next());
  }

  return result;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief counts the number of documents
///
/// @FUN{@FA{cursor}.count()}
///
/// The @FN{count} operator counts the number of document in the result set and
/// returns that number. The @FN{count} operator ignores any limits and returns
/// the total number of documents found.
///
/// @note Not all simple queries support counting. In this case @LIT{null} is
/// returned.
///
/// @FUN{@FA{cursor}.count(@LIT{true})}
///
/// If the result set was limited by the @FN{limit} operator or documents were
/// skiped using the @FN{skip} operator, the @FN{count} operator with argument
/// @LIT{true} will use the number of elements in the final result set - after
/// applying @FN{limit} and @FN{skip}.
///
/// @note Not all simple queries support counting. In this case @LIT{null} is
/// returned.
///
/// @EXAMPLES
///
/// Ignore any limit:
///
/// @verbinclude simple9
///
/// Counting any limit or skip:
///
/// @verbinclude simple10
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.count = function (applyPagination) {
  this.execute();

  if (applyPagination === undefined || ! applyPagination) {
    return this._countTotal;
  }
  else {
    return this._countQuery;
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief checks if the cursor is exhausted
///
/// @FUN{@FA{cursor}.hasNext()}
///
/// The @FN{hasNext} operator returns @LIT{true}, then the cursor still has
/// documents.  In this case the next document can be accessed using the
/// @FN{next} operator, which will advance the cursor.
///
/// @EXAMPLES
///
/// @verbinclude simple7
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.hasNext = function () {
  this.execute();

  return this._execution.hasNext();
}

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the next result document
///
/// @FUN{@FA{cursor}.next()}
///
/// If the @FN{hasNext} operator returns @LIT{true}, then the underlying
/// cursor of the simple query still has documents.  In this case the
/// next document can be accessed using the @FN{next} operator, which
/// will advance the underlying cursor. If you use @FN{next} on an
/// exhausted cursor, then @LIT{undefined} is returned.
///
/// @EXAMPLES
///
/// @verbinclude simple5
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.next = function() {
  this.execute();

  return this._execution.next();
}

////////////////////////////////////////////////////////////////////////////////
/// @brief disposes the result
///
/// @FUN{@FA{cursor}.dispose()}
///
/// If you are no longer interested in any further results, you should call
/// @FN{dispose} in order to free any resources associated with the cursor.
/// After calling @FN{dispose} you can no longer access the cursor.
////////////////////////////////////////////////////////////////////////////////

SimpleQuery.prototype.dispose = function() {
  if (this._execution != null) {
    this._execution.dispose();
  }

  this._execution = null;
  this._countQuery = null;
  this._countTotal = null;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  SIMPLE QUERY ALL
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief all query
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryAll (collection) {
  this._collection = collection;
}

SimpleQueryAll.prototype = new SimpleQuery();
SimpleQueryAll.prototype.constructor = SimpleQueryAll;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs an all query for a collection
///
/// @FUN{all()}
///
/// Selects all documents of a collection and returns a cursor. You can use
/// @FN{toArray}, @FN{next}, or @FN{hasNext} to access the result. The result
/// can be limited using the @FN{skip} and @FN{limit} operator.
///
/// @EXAMPLES
///
/// Use @FN{toArray} to get all documents at once:
///
/// @verbinclude simple3
///
/// Use @FN{next} to loop over all documents:
///
/// @verbinclude simple4
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.all = function () {
  return new SimpleQueryAll(this);
}

ArangoEdgesCollection.prototype.all = ArangoCollection.prototype.all;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryAll.prototype.clone = function () {
  var query;

  query = new SimpleQueryAll(this._collection);
  query._skip = this._skip;
  query._limit = this._limit;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief print an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryAll.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryAll(" + this._collection.name() + ")";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                SIMPLE QUERY ARRAY
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief array query
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryArray (documents) {
  this._documents = documents;
}

SimpleQueryArray.prototype = new SimpleQuery();
SimpleQueryArray.prototype.constructor = SimpleQueryArray;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryArray.prototype.clone = function () {
  var query;

  query = new SimpleQueryArray(this._documents);
  query._skip = this._skip;
  query._limit = this._limit;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief executes an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryArray.prototype.execute = function () {
  if (this._execution === null) {
    if (this._skip === null) {
      this._skip = 0;
    }

    this._execution = new GeneralArrayCursor(this._documents, this._skip, this._limit);
  }
}

////////////////////////////////////////////////////////////////////////////////
/// @brief print an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryArray.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryArray(documents)";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  QUERY BY EXAMPLE
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief query-by-example
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryByExample (collection, example) {
  this._collection = collection;
  this._example = example;
}

SimpleQueryByExample.prototype = new SimpleQuery();
SimpleQueryByExample.prototype.constructor = SimpleQueryByExample;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a query-by-example for a collection
///
/// @FUN{@FA{collection}.byExample(@FA{example})}
///
/// Selects all documents of a collection that match the specified
/// example and returns a cursor. 
///
/// You can use @FN{toArray}, @FN{next}, or @FN{hasNext} to access the
/// result. The result can be limited using the @FN{skip} and @FN{limit}
/// operator.
///
/// An attribute name of the form @LIT{a.b} is interpreted as attribute path,
/// not as attribute. If you use 
/// 
/// @LIT{{ a : { c : 1 } }} 
///
/// as example, then you will find all documents, such that the attribute
/// @LIT{a} contains a document of the form @LIT{{c : 1 }}. E.g., the document
///
/// @LIT{{ a : { c : 1 }\, b : 1 }} 
///
/// will match, but the document 
///
/// @LIT{{ a : { c : 1\, b : 1 } }}
///
/// will not.
///
/// However, if you use 
///
/// @LIT{{ a.c : 1 }}, 
///
/// then you will find all documents, which contain a sub-document in @LIT{a}
/// that has an attribute @LIT{c} of value @LIT{1}. E.g., both documents 
///
/// @LIT{{ a : { c : 1 }\, b : 1 }} and 
///
/// @LIT{{ a : { c : 1\, b : 1 } }}
///
/// will match.
///
/// @FUN{@FA{collection}.byExample(@FA{path1}, @FA{value1}, ...)}
///
/// As alternative you can supply a list of paths and values.
///
/// @EXAMPLES
///
/// Use @FN{toArray} to get all documents at once:
///
/// @TINYEXAMPLE{simple18,convert into a list}
///
/// Use @FN{next} to loop over all documents:
///
/// @TINYEXAMPLE{simple19,iterate over the result-set}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.byExample = function () {
  var example;

  // example is given as only argument
  if (arguments.length === 1) {
    example = arguments[0];
  }

  // example is given as list
  else {
    example = {};

    for (var i = 0;  i < arguments.length;  i += 2) {
      example[arguments[i]] = arguments[i + 1];
    }
  }

  // create a REAL array, otherwise JSON.stringify will fail
  return new SimpleQueryByExample(this, example);
}

ArangoEdgesCollection.prototype.byExample = ArangoCollection.prototype.byExample;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones a query-by-example
////////////////////////////////////////////////////////////////////////////////

SimpleQueryByExample.prototype.clone = function () {
  var query;

  query = new SimpleQueryByExample(this._collection, this._example);
  query._skip = this._skip;
  query._limit = this._limit;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief print a query-by-example
////////////////////////////////////////////////////////////////////////////////

SimpleQueryByExample.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryByExample(" + this._collection.name() + ")";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                       RANGE QUERY
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief range query
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryRange (collection, attribute, left, right, type) {
  this._collection = collection;
  this._attribute = attribute;
  this._left = left;
  this._right = right;
  this._type = type;
}

SimpleQueryRange.prototype = new SimpleQuery();
SimpleQueryRange.prototype.constructor = SimpleQueryRange;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a range query for a collection
///
/// @FUN{@FA{collection}.range(@FA{attribute}, @FA{left}, @FA{right})}
///
/// Selects all documents of a collection such that the @FA{attribute} is
/// greater or equal than @FA{left} and strictly less than @FA{right}.
///
/// You can use @FN{toArray}, @FN{next}, or @FN{hasNext} to access the
/// result. The result can be limited using the @FN{skip} and @FN{limit}
/// operator.
///
/// An attribute name of the form @LIT{a.b} is interpreted as attribute path,
/// not as attribute.
///
/// @EXAMPLES
///
/// Use @FN{toArray} to get all documents at once:
///
/// @TINYEXAMPLE{simple-query-range-to-array,convert into a list}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.range = function (name, left, right) {
  return new SimpleQueryRange(this, name, left, right, 0);
}

ArangoEdgesCollection.prototype.range = ArangoCollection.prototype.range;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a closed range query for a collection
///
/// @FUN{@FA{collection}.closedRange(@FA{attribute}, @FA{left}, @FA{right})}
///
/// Selects all documents of a collection such that the @FA{attribute} is
/// greater or equal than @FA{left} and less or equal than @FA{right}.
///
/// You can use @FN{toArray}, @FN{next}, or @FN{hasNext} to access the
/// result. The result can be limited using the @FN{skip} and @FN{limit}
/// operator.
///
/// An attribute name of the form @LIT{a.b} is interpreted as attribute path,
/// not as attribute.
///
/// @EXAMPLES
///
/// Use @FN{toArray} to get all documents at once:
///
/// @TINYEXAMPLE{simple-query-closed-range-to-array,convert into a list}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.closedRange = function (name, left, right) {
  return new SimpleQueryRange(this, name, left, right, 1);
}

ArangoEdgesCollection.prototype.closedRange = ArangoCollection.prototype.closedRange;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones a range query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryRange.prototype.clone = function () {
  var query;

  query = new SimpleQueryRange(this._collection, this._attribute, this._left, this._right, this._type);
  query._skip = this._skip;
  query._limit = this._limit;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief prints a range query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryRange.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryRange(" + this._collection.name() + ")";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  SIMPLE QUERY GEO
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief geo index
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryGeo (collection, index) {
  this._collection = collection;
  this._index = index;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a geo index selection
///
/// @FUN{@FA{collection}.geo(@FA{location})}
////////////////////////////////////////////
///
/// The next @FN{near} or @FN{within} operator will use the specific geo-spatial
/// index.
///
/// @FUN{@FA{collection}.geo(@FA{location}, @LIT{true})}
////////////////////////////////////////////////////////
///
/// The next @FN{near} or @FN{within} operator will use the specific geo-spatial
/// index.
///
/// @FUN{@FA{collection}.geo(@FA{latitude}, @FA{longitude})}
////////////////////////////////////////////////////////////
///
/// The next @FN{near} or @FN{within} operator will use the specific geo-spatial
/// index.
///
/// @EXAMPLES
///
/// Assume you have a location stored as list in the attribute @LIT{home}
/// and a destination stored in the attribute @LIT{work}. Than you can use the
/// @FN{geo} operator to select, which coordinates to use in a near query.
///
/// @TINYEXAMPLE{simple-query-geo,use a specific index}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.geo = function(loc, order) {
  var idx;

  var locateGeoIndex1 = function(collection, loc, order) {
    var inds = collection.getIndexes();
    
    for (var i = 0;  i < inds.length;  ++i) {
      var index = inds[i];
      
      if (index.type === "geo1") {
        if (index.fields[0] === loc && index.geoJson === order) {
          return index;
        }
      }
    }
    
    return null;
  };

  var locateGeoIndex2 = function(collection, lat, lon) {
    var inds = collection.getIndexes();
    
    for (var i = 0;  i < inds.length;  ++i) {
      var index = inds[i];
      
      if (index.type === "geo2") {
        if (index.fields[0] === lat && index.fields[1] === lon) {
          return index;
        }
      }
    }
    
    return null;
  };

  if (order === undefined) {
    if (typeof loc === "object") {
      idx = this.index(loc);
    }
    else {
      idx = locateGeoIndex1(this, loc, false);
    }
  }
  else if (typeof order === "boolean") {
    idx = locateGeoIndex1(this, loc, order);
  }
  else {
    idx = locateGeoIndex2(this, loc, order);
  }

  if (idx === null) {
    var err = new ArangoError();
    err.errorNum = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.code;
    err.errorMessage = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.message;
    throw err;
  }

  return new SimpleQueryGeo(this, idx.id);
}

ArangoEdgesCollection.prototype.geo = ArangoCollection.geo;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief prints a geo index
////////////////////////////////////////////////////////////////////////////////

SimpleQueryGeo.prototype._PRINT = function () {
  var text;

  text = "GeoIndex("
       + this._collection.name()
       + ", "
       + this._index
       + ")";

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a near query for an index
////////////////////////////////////////////////////////////////////////////////

SimpleQueryGeo.prototype.near = function (lat, lon) {
  return new SimpleQueryNear(this._collection, lat, lon, this._index);
}

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a within query for an index
////////////////////////////////////////////////////////////////////////////////

SimpleQueryGeo.prototype.within = function (lat, lon, radius) {
  return new SimpleQueryWithin(this._collection, lat, lon, radius, this._index);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 SIMPLE QUERY NEAR
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief near query
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryNear (collection, latitude, longitude, iid) {
  var idx;

  this._collection = collection;
  this._latitude = latitude;
  this._longitude = longitude;
  this._index = (iid === undefined ? null : iid);
  this._distance = null;

  if (iid === undefined) {
    idx = collection.getIndexes();
    
    for (var i = 0;  i < idx.length;  ++i) {
      var index = idx[i];
      
      if (index.type === "geo1" || index.type === "geo2") {
        if (this._index === null) {
          this._index = index.id;
        }
        else if (index.id < this._index) {
          this._index = index.id;
        }
      }
    }
  }
    
  if (this._index === null) {
    var err = new ArangoError();
    err.errorNum = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.code;
    err.errorMessage = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.message;
    throw err;
  }
}

SimpleQueryNear.prototype = new SimpleQuery();
SimpleQueryNear.prototype.constructor = SimpleQueryNear;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a near query for a collection
///
/// @FUN{@FA{collection}.near(@FA{latitude}, @FA{longitude})}
/////////////////////////////////////////////////////////////
///
/// The default will find at most 100 documents near the coordinate
/// (@FA{latitude}, @FA{longitude}). The returned list is sorted according to
/// the distance, with the nearest document coming first. If there are near
/// documents of equal distance, documents are chosen randomly from this set
/// until the limit is reached. It is possible to change the limit using the
/// @FA{limit} operator.
///
/// In order to use the @FN{near} operator, a geo index must be defined for the
/// collection. This index also defines which attribute holds the coordinates
/// for the document.  If you have more then one geo-spatial index, you can use
/// the @FN{geo} operator to select a particular index.
///
/// @note @FN{near} does not support negative skips. However, you can still use
/// @FN{limit} followed to @FN{skip}.
///
/// @FUN{@FA{collection}.near(@FA{latitude}, @FA{longitude}).limit(@FA{limit})}
///////////////////////////////////////////////////////////////////////////////
///
/// Limits the result to @FA{limit} documents instead of the default 100.
///
/// @note Unlike with multiple explicit limits, @FA{limit} will raise
/// the implicit default limit imposed by @FN{within}.
///
/// @FUN{@FA{collection}.near(@FA{latitude}, @FA{longitude}).distance()}
////////////////////////////////////////////////////////////////////////
///
/// This will add an attribute @LIT{distance} to all documents returned, which
/// contains the distance between the given point and the document in meter.
///
/// @FUN{@FA{collection}.near(@FA{latitude}, @FA{longitude}).distance(@FA{name})}
/////////////////////////////////////////////////////////////////////////////////
///
/// This will add an attribute @FA{name} to all documents returned, which
/// contains the distance between the given point and the document in meter.
///
/// @EXAMPLES
///
/// To get the nearst two locations:
///
/// @TINYEXAMPLE{simple-query-near,nearest two location}
///
/// If you need the distance as well, then you can use the @FN{distance}
/// operator:
///
/// @TINYEXAMPLE{simple-query-near2,nearest two location with distance in meter}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.near = function (lat, lon) {
  return new SimpleQueryNear(this, lat, lon);
}

ArangoEdgesCollection.prototype.near = ArangoCollection.prototype.near;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryNear.prototype.clone = function () {
  var query;

  query = new SimpleQueryNear(this._collection, this._latitude, this._longitude, this._index);
  query._skip = this._skip;
  query._limit = this._limit;
  query._distance = this._distance;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief prints a near query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryNear.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryNear("
       + this._collection.name()
       + ", "
       + this._latitude
       + ", "
       + this._longitude
       + ", "
       + this._index
       + ")";

  if (this._skip != null && this._skip != 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit != null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief adds the distance attribute
////////////////////////////////////////////////////////////////////////////////

SimpleQueryNear.prototype.distance = function (attribute) {
  var clone;

  clone = this.clone();

  if (attribute) {
    clone._distance = attribute;
  }
  else {
    clone._distance = "distance";
  }

  return clone;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                               SIMPLE QUERY WITHIN
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief within query
////////////////////////////////////////////////////////////////////////////////

function SimpleQueryWithin (collection, latitude, longitude, radius, iid) {
  var idx;

  this._collection = collection;
  this._latitude = latitude;
  this._longitude = longitude;
  this._index = (iid === undefined ? null : iid);
  this._radius = radius;
  this._distance = null;

  if (iid === undefined) {
    idx = collection.getIndexes();
    
    for (var i = 0;  i < idx.length;  ++i) {
      var index = idx[i];
      
      if (index.type === "geo1" || index.type === "geo2") {
        if (this._index === null) {
          this._index = index.id;
        }
        else if (index.id < this._index) {
          this._index = index.id;
        }
      }
    }
  }
    
  if (this._index === null) {
    var err = new ArangoError();
    err.errorNum = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.code;
    err.errorMessage = internal.errors.ERROR_QUERY_GEO_INDEX_MISSING.message;
    throw err;
  }
}

SimpleQueryWithin.prototype = new SimpleQuery();
SimpleQueryWithin.prototype.constructor = SimpleQueryWithin;

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a within query for a collection
///
/// @FUN{@FA{collection}.within(@FA{latitude}, @FA{longitude}, @FA{radius})}
////////////////////////////////////////////////////////////////////////////
///
/// This will find all documents with in a given radius around the coordinate
/// (@FA{latitude}, @FA{longitude}). The returned list is sorted by distance.
///
/// In order to use the @FN{within} operator, a geo index must be defined for the
/// collection. This index also defines which attribute holds the coordinates
/// for the document.  If you have more then one geo-spatial index, you can use
/// the @FN{geo} operator to select a particular index.
///
/// @FUN{@FA{collection}.within(@FA{latitude}, @FA{longitude}, @FA{radius})@LATEXBREAK.distance()}
//////////////////////////////////////////////////////////////////////////////////////////////////
///
/// This will add an attribute @LIT{_distance} to all documents returned, which
/// contains the distance between the given point and the document in meter.
///
/// @FUN{@FA{collection}.within(@FA{latitude}, @FA{longitude}, @FA{radius})@LATEXBREAK.distance(@FA{name})}
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///
/// This will add an attribute @FA{name} to all documents returned, which
/// contains the distance between the given point and the document in meter.
///
/// @EXAMPLES
///
/// To find all documents within a radius of 2000 km use:
///
/// @TINYEXAMPLE{simple-query-within,within a radius}
////////////////////////////////////////////////////////////////////////////////

ArangoCollection.prototype.within = function (lat, lon, radius) {
  return new SimpleQueryWithin(this, lat, lon, radius);
}

ArangoEdgesCollection.prototype.within = ArangoCollection.prototype.within;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                 private functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief clones an all query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryWithin.prototype.clone = function () {
  var query;

  query = new SimpleQueryWithin(this._collection, this._latitude, this._longitude, this._radius, this._index);
  query._skip = this._skip;
  query._limit = this._limit;
  query._distance = this._distance;

  return query;
}

////////////////////////////////////////////////////////////////////////////////
/// @brief prints a within query
////////////////////////////////////////////////////////////////////////////////

SimpleQueryWithin.prototype._PRINT = function () {
  var text;

  text = "SimpleQueryWithin("
       + this._collection.name()
       + ", "
       + this._latitude
       + ", "
       + this._longitude
       + ", "
       + this._radius
       + ", "
       + this._index
       + ")";

  if (this._skip !== null && this._skip !== 0) {
    text += ".skip(" + this._skip + ")";
  }

  if (this._limit !== null) {
    text += ".limit(" + this._limit + ")";
  }

  internal.output(text);
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief adds the distance attribute
////////////////////////////////////////////////////////////////////////////////

SimpleQueryWithin.prototype.distance = function (attribute) {
  var clone;

  clone = this.clone();

  if (attribute) {
    clone._distance = attribute;
  }
  else {
    clone._distance = "distance";
  }

  return clone;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                    MODULE EXPORTS
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup SimpleQuery
/// @{
////////////////////////////////////////////////////////////////////////////////

exports.GeneralArrayCursor = GeneralArrayCursor;
exports.SimpleQueryAll = SimpleQueryAll;
exports.SimpleQueryArray = SimpleQueryArray;
exports.SimpleQueryByExample = SimpleQueryByExample;
exports.SimpleQueryRange = SimpleQueryRange;
exports.SimpleQueryGeo = SimpleQueryGeo;
exports.SimpleQueryNear = SimpleQueryNear;
exports.SimpleQueryWithin = SimpleQueryWithin;

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
});
