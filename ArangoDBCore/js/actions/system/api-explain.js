////////////////////////////////////////////////////////////////////////////////
/// @brief query explain actions
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
/// @author Jan Steemann
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup ArangoAPI
/// @{
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  global variables
// -----------------------------------------------------------------------------

var actions = require("org/arangodb/actions");

////////////////////////////////////////////////////////////////////////////////
/// @brief explain a query and return information about it
///
/// @RESTHEADER{POST /_api/explain,explains a query}
///
/// @REST{POST /_api/explain}
///
/// To explain how an AQL query would be executed on the server, the query string 
/// can be sent to the server via an HTTP POST request. The server will then validate
/// the query and create an execution plan for it, but will not execute it.
///
/// The execution plan that is returned by the server can be used to estimate the
/// probable performance of an AQL query. Though the actual performance will depend
/// on many different factors, the execution plan normally can give some good hint
/// on the amount of work the server needs to do in order to actually run the query. 
///
/// The query string needs to be passed in the attribute @LIT{query} of a JSON
/// object as the body of the POST request. If the query references any bind 
/// variables, these must also be passed in the attribute @LIT{bindVars}.
///
/// If the query is valid, the server will respond with @LIT{HTTP 200} and
/// return a list of the individual query execution steps in the @LIT{"plan"}
/// attribute of the response.
///
/// The server will respond with @LIT{HTTP 400} in case of a malformed request,
/// or if the query contains a parse error. The body of the response will
/// contain the error details embedded in a JSON object.
/// Omitting bind variables if the query references any will result also result
/// in an @LIT{HTTP 400} error.
///
/// @EXAMPLES
///
/// Valid query:
///
/// @verbinclude api-explain-valid
///
/// Invalid query:
///
/// @verbinclude api-explain-invalid
///
/// The data returned in the @LIT{plan} attribute of the result contains one
/// element per AQL top-level statement (i.e. @LIT{FOR}, @LIT{RETURN}, 
/// @LIT{FILTER} etc.). If the query optimiser removed some unnecessary statements,
/// the result might also contain less elements than there were top-level
/// statements in the AQL query.
/// The following example shows a query with a non-sensible filter condition that
/// the optimiser has removed so that there are less top-level statements:
///
/// @verbinclude api-explain-empty
///
/// The top-level statements will appear in the result in the same order in which
/// they have been used in the original query. Each result element has at most the 
/// following attributes:
/// - @LIT{id}: the row number of the top-level statement, starting at 1
/// - @LIT{type}: the type of the top-level statement (e.g. @LIT{for}, @LIT{return} ...)
/// - @LIT{loopLevel}: the nesting level of the top-level statement, starting at 1
/// Depending on the type of top-level statement, there might be other attributes
/// providing additional information, for example, if and which indexed will be
/// used.
/// Many top-level statements will provide an @LIT{expression} attribute that
/// contains data about the expression they operate on. This is true for @LIT{FOR},
/// @LIT{FILTER}, @LIT{SORT}, @LIT{COLLECT}, and @LIT{RETURN} statements. The 
/// @LIT{expression} attribute has the following sub-attributes:
/// - @LIT{type}: the type of the expression. Some possible values are:
///   - @LIT{collection}: an iteration over documents from a collection. The 
///     @LIT{value} attribute will then contain the collection name. The @LIT{extra}
///     attribute will contain information about if and which index is used when
///     accessing the documents from the collection. If no index is used, the 
///     @LIT{accessType} sub-attribute of the @LIT{extra} attribute will have the
///     value @LIT{all}, otherwise it will be @LIT{index}.
///   - @LIT{list}: a list of dynamic values. The @LIT{value} attribute will contain the
///     list elements.
///   - @LIT{const list}: a list of constant values. The @LIT{value} attribute will contain the
///     list elements.
///   - @LIT{reference}: a reference to another variable. The @LIT{value} attribute
///     will contain the name of the variable that is referenced.
///
/// Please note that the structure of the explain result data might change in future
/// versions of ArangoDB without further notice and without maintaining backwards
/// compatibility. 
////////////////////////////////////////////////////////////////////////////////

function POST_api_explain (req, res) {
  if (req.suffix.length != 0) {
    actions.resultNotFound(req, res, actions.ERROR_HTTP_NOT_FOUND);
    return;
  }

  var json = actions.getJsonBody(req, res);

  if (json === undefined) {
    return;
  }

  var result = AHUACATL_EXPLAIN(json.query, json.bindVars);

  if (result instanceof ArangoError) {
    actions.resultBad(req, res, result.errorNum, result.errorMessage);
    return;
  }

  result = { "plan" : result };
  actions.resultOk(req, res, actions.HTTP_OK, result);
}

// -----------------------------------------------------------------------------
// --SECTION--                                                       initialiser
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief explain gateway 
////////////////////////////////////////////////////////////////////////////////

actions.defineHttp({
  url : "_api/explain",
  context : "api",

  callback : function (req, res) {
    try {
      switch (req.requestType) {
        case (actions.POST) : 
          POST_api_explain(req, res); 
          break;

        default:
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

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
