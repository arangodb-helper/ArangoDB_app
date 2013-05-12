/*jslint indent: 2, nomen: true, maxlen: 100, sloppy: true, vars: true, white: true, plusplus: true */
/*global require, exports */

////////////////////////////////////////////////////////////////////////////////
/// @brief Graph functionality
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2010-2012 triagens GmbH, Cologne, Germany
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
/// @author Dr. Frank Celler, Lucas Dohmen
/// @author Copyright 2011-2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

var arangodb = require("org/arangodb");
var arangosh = require("org/arangodb/arangosh");

var ArangoQueryCursor = require("org/arangodb/arango-query-cursor").ArangoQueryCursor;

var GraphArray;

// -----------------------------------------------------------------------------
// --SECTION--                                       module "org/arangodb/graph"
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                                              Edge
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a new edge object
////////////////////////////////////////////////////////////////////////////////

function Edge (graph, properties) {
  this._graph = graph;
  this._id = properties._key;
  this._properties = properties;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the to vertex
////////////////////////////////////////////////////////////////////////////////

Edge.prototype.getInVertex = function () {
  return this._graph.getVertex(this._properties._to);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the from vertex
////////////////////////////////////////////////////////////////////////////////

Edge.prototype.getOutVertex = function () {
  return this._graph.getVertex(this._properties._from);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the other vertex
////////////////////////////////////////////////////////////////////////////////

Edge.prototype.getPeerVertex = function (vertex) {
  if (vertex._properties._id === this._properties._to) {
    return this._graph.getVertex(this._properties._from);
  }

  if (vertex._properties._id === this._properties._from) {
    return this._graph.getVertex(this._properties._to);
  }

  return null;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief changes a property of an edge
////////////////////////////////////////////////////////////////////////////////

Edge.prototype.setProperty = function (name, value) {
  var requestResult;
  var update = this._properties;

  update[name] = value;

  requestResult = this._graph._connection.PUT("/_api/graph/"
    + encodeURIComponent(this._graph._properties._key)
    + "/edge/"
    + encodeURIComponent(this._properties._key),
    JSON.stringify(update));

  arangosh.checkRequestResult(requestResult);

  this._properties = requestResult.edge;

  return name;
};

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                            Vertex
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a new vertex object
////////////////////////////////////////////////////////////////////////////////

function Vertex (graph, properties) {
  this._graph = graph;
  this._id = properties._key;
  this._properties = properties;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief inbound and outbound edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.edges = function () {
  var graph = this._graph;
  var requestResult;
  var edges;
  var cursor;

  requestResult = graph._connection.POST("/_api/graph/"
    + encodeURIComponent(graph._properties._key)
    + "/edges/"
    + encodeURIComponent(this._properties._key),
  '{ "filter" : { "direction" : "any" } }');

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(graph._vertices._database, requestResult);
  edges = new GraphArray();

  while (cursor.hasNext()) {
    var edge = new Edge(graph, cursor.next());

    edges.push(edge);
  }

  return edges;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief inbound edges with given label
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.getInEdges = function () {
  var labels = Array.prototype.slice.call(arguments);
  var graph = this._graph;
  var requestResult;
  var edges;
  var cursor;

  requestResult = graph._connection.POST("/_api/graph/"
    + encodeURIComponent(graph._properties._key)
    + "/edges/"
    + encodeURIComponent(this._properties._key),
    JSON.stringify({ filter : { direction : "in", labels: labels } }));

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(graph._vertices._database, requestResult);
  edges = new GraphArray();

  while (cursor.hasNext()) {
    var edge = new Edge(graph, cursor.next());

    edges.push(edge);
  }

  return edges;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief outbound edges with given label
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.getOutEdges = function () {
  var labels = Array.prototype.slice.call(arguments);
  var graph = this._graph;
  var requestResult;
  var edges;
  var cursor;

  requestResult = graph._connection.POST("/_api/graph/"
    + encodeURIComponent(graph._properties._key)
    + "/edges/"
    + encodeURIComponent(this._properties._key),
    JSON.stringify({ filter : { direction : "out", labels: labels } }));

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(graph._vertices._database, requestResult);
  edges = new GraphArray();

  while (cursor.hasNext()) {
    var edge = new Edge(graph, cursor.next());

    edges.push(edge);
  }

  return edges;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief in- or outbound edges with given label
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.getEdges = function () {
  var labels = Array.prototype.slice.call(arguments);
  var graph = this._graph;
  var requestResult;
  var edges;
  var cursor;

  requestResult = graph._connection.POST("/_api/graph/"
    + encodeURIComponent(graph._properties._key)
    + "/edges/"
    + encodeURIComponent(this._properties._key),
    JSON.stringify({ filter : { labels: labels } }));

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(graph._vertices._database, requestResult);
  edges = new GraphArray();

  while (cursor.hasNext()) {
    var edge = new Edge(graph, cursor.next());

    edges.push(edge);
  }

  return edges;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief inbound edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.inbound = function () {
  return this.getInEdges();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief outbound edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.outbound = function () {
  return this.getOutEdges();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief changes a property of a vertex
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.setProperty = function (name, value) {
  var requestResult;
  var update = this._properties;

  update[name] = value;

  requestResult = this._graph._connection.PUT("/_api/graph/"
    + encodeURIComponent(this._graph._properties._key)
    + "/vertex/"
    + encodeURIComponent(this._properties._key),
    JSON.stringify(update));

  arangosh.checkRequestResult(requestResult);

  this._properties = requestResult.vertex;

  return name;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the number of edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.degree = function () {
  return this.getEdges().length;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the number of in-edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.inDegree = function () {
  return this.getInEdges().length;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the number of out-edges
////////////////////////////////////////////////////////////////////////////////

Vertex.prototype.outDegree = function () {
  return this.getOutEdges().length;
};

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                             Graph
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief constructs a new graph object
////////////////////////////////////////////////////////////////////////////////

function Graph (name, vertices, edges) {
  var requestResult;

  if (vertices === undefined && edges === undefined) {
    requestResult = arangodb.arango.GET("/_api/graph/" + encodeURIComponent(name));
  }
  else {
    requestResult = arangodb.arango.POST("/_api/graph", JSON.stringify({
      _key: name,
      vertices: vertices,
      edges: edges
    }));
  }

  arangosh.checkRequestResult(requestResult);

  this._properties = requestResult.graph;
  this._vertices = arangodb.db._collection(this._properties.vertices);
  this._edges = arangodb.db._collection(this._properties.edges);
  this._connection = arangodb.arango;

  return this;
}

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                    public methods
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief drops the graph, the vertices, and the edges
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.drop = function () {
  var requestResult;

  requestResult = this._connection.DELETE("/_api/graph/"
    + encodeURIComponent(this._properties._key));

  arangosh.checkRequestResult(requestResult);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief adds an edge to the graph
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.addEdge = function (out_vertex, in_vertex, id, label, data) {
  var requestResult;
  var params;
  var key;

  if (data === null || typeof data !== "object") {
    params = {};
  }
  else {
    params = data._shallowCopy || {};
  }

  params._key = id;
  params._from = out_vertex._properties._key;
  params._to = in_vertex._properties._key;
  params.$label = label;

  requestResult = this._connection.POST("/_api/graph/"
    + encodeURIComponent(this._properties._key) + "/edge",
    JSON.stringify(params));

  arangosh.checkRequestResult(requestResult);

  return new Edge(this, requestResult.edge);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief adds a vertex to the graph
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.addVertex = function (id, data) {
  var requestResult;
  var params;
  var key;

  if (data === null || typeof data !== "object") {
    params = {};
  }
  else {
    params = data._shallowCopy || {};
  }

  if (id !== undefined) {
    params._key = id;
  }

  requestResult = this._connection.POST("/_api/graph/"
    + encodeURIComponent(this._properties._key) + "/vertex",
    JSON.stringify(params));

  arangosh.checkRequestResult(requestResult);

  return new Vertex(this, requestResult.vertex);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns a vertex given its id
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.getVertex = function (id) {
  var requestResult;

  requestResult = this._connection.GET("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/vertex/"
    + encodeURIComponent(id));

  if (requestResult.error === true && requestResult.code === 404) {
    return null;
  }

  arangosh.checkRequestResult(requestResult);

  if (requestResult.vertex !== null) {
    return new Vertex(this, requestResult.vertex);
  }

  return null;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns an iterator for all vertices
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.getVertices = function () {
  var that = this;
  var requestResult;
  var cursor;
  var Iterator;

  requestResult = this._connection.POST("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/vertices",
    "{}");

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(this._vertices._database, requestResult);

  Iterator = function () {
    this.next = function next() {
      if (cursor.hasNext()) {
        return new Vertex(that, cursor.next());
      }

      return undefined;
    };

    this.hasNext = function hasNext() {
      return cursor.hasNext();
    };

    this._PRINT = function (context) {
      context.output += "[vertex iterator]";
    };
  };

  return new Iterator();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns an edge given its id
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.getEdge = function (id) {
  var requestResult;

  requestResult = this._connection.GET("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/edge/"
    + encodeURIComponent(id));

  if (requestResult.error === true && requestResult.code === 404) {
    return null;
  }

  arangosh.checkRequestResult(requestResult);

  if (requestResult.edge !== null) {
    return new Edge(this, requestResult.edge);
  }

  return null;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns an iterator for all edges
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.getEdges = function () {
  var that = this;
  var requestResult;
  var cursor;
  var Iterator;

  requestResult = this._connection.POST("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/edges",
    "{}");

  arangosh.checkRequestResult(requestResult);

  cursor = new ArangoQueryCursor(this._vertices._database, requestResult);

  Iterator = function () {
    this.next = function next() {
      if (cursor.hasNext()) {
        return new Edge(that, cursor.next());
      }

      return undefined;
    };

    this.hasNext = function hasNext() {
      return cursor.hasNext();
    };

    this._PRINT = function (context) {
      context.output += "[edge iterator]";
    };
  };

  return new Iterator();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief removes a vertex and all in- or out-bound edges
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.removeVertex = function (vertex) {
  var requestResult;

  requestResult = this._connection.DELETE("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/vertex/"
    + encodeURIComponent(vertex._properties._key));

  arangosh.checkRequestResult(requestResult);

  vertex._properties = undefined;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief removes an edge
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.removeEdge = function (edge) {
  var requestResult;

  requestResult = this._connection.DELETE("/_api/graph/"
    + encodeURIComponent(this._properties._key)
    + "/edge/"
    + encodeURIComponent(edge._properties._key));

  arangosh.checkRequestResult(requestResult);

  edge._properties = undefined;
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the number of vertices
///
/// @FUN{@FA{graph}.order()}
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.order = function () {
  return this._vertices.count();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief returns the number of edges
///
/// @FUN{@FA{graph}.size()}
////////////////////////////////////////////////////////////////////////////////

Graph.prototype.size = function () {
  return this._edges.count();
};

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                    MODULE EXPORTS
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoGraph
/// @{
////////////////////////////////////////////////////////////////////////////////

exports.Edge = Edge;
exports.Graph = Graph;
exports.Vertex = Vertex;
exports.GraphArray = GraphArray;

var common = require("org/arangodb/graph-common");

exports.GraphArray = GraphArray = common.GraphArray;

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
