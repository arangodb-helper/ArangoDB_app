////////////////////////////////////////////////////////////////////////////////
/// @brief tests for query language, logical operators
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
/// @author Jan Steemann
/// @author Copyright 2012, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

var internal = require("internal");
var jsunity = require("jsunity");

////////////////////////////////////////////////////////////////////////////////
/// @brief test suite
////////////////////////////////////////////////////////////////////////////////

function ahuacatlLogicalTestSuite () {
  var errors = internal.errors;

////////////////////////////////////////////////////////////////////////////////
/// @brief execute a given query
////////////////////////////////////////////////////////////////////////////////

  function executeQuery (query) {
    return AHUACATL_RUN(query, undefined);
  }

////////////////////////////////////////////////////////////////////////////////
/// @brief execute a given query and return the results as an array
////////////////////////////////////////////////////////////////////////////////

  function getQueryResults (query) {
    var result = executeQuery(query).getRows();
    var results = [ ];

    for (var i in result) {
      if (!result.hasOwnProperty(i)) {
        continue;
      }

      results.push(result[i]);
    }

    return results;
  }

////////////////////////////////////////////////////////////////////////////////
/// @brief return the error code from a result
////////////////////////////////////////////////////////////////////////////////

  function getErrorCode (fn) {
    try {
      fn();
    }
    catch (e) {
      return e.errorNum;
    }
  }


  return {

////////////////////////////////////////////////////////////////////////////////
/// @brief set up
////////////////////////////////////////////////////////////////////////////////

    setUp : function () {
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief tear down
////////////////////////////////////////////////////////////////////////////////

    tearDown : function () {
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot1 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN !true");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot2 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN !false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot3 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN !!false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot4 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN !!!false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot5 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN !(1 == 1)");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot6 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN !(!(1 == 1))");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNot7 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN !true == !!false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNotInvalid : function () {
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !null"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !0"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !\"value\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN ![]"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !{}"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unary not
////////////////////////////////////////////////////////////////////////////////
    
    testUnaryNotPrecedence : function () {
      // not has higher precedence than ==
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !1 == 0"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !1 == !1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !1 > 7"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN !1 IN [1]"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAnd1 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN true && true");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAnd2 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN true && false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAnd3 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN false && true");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAnd4 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN false && false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAnd5 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN true && !false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and 
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAndInvalid : function () {
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN null && true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN 1 && true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"\" && true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"false\" && true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN [ ] && true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN { } && true"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && null"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && 1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && \"\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && \"false\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && [ ]"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true && { }"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN null && false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN 1 && false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"\" && false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"false\" && false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN [ ] && false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN { } && false"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && null"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && 1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && \"\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && \"false\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && [ ]"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false && { }"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and, short circuit evaluation
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAndShortCircuit1 : function () {
      // TODO: FIXME                              
      // var expected = [ false ];
      // var actual = getQueryResults("RETURN false && FAIL('this will fail')");
      //assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary and, short circuit evaluation
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryAndShortCircuit2 : function () {
      assertException(function() { getQueryResults("RETURN false && FAIL('this will fail')"); });
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr1 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN true || true");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr2 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN true || false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr3 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN false || true");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr4 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN false || false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr5 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN true || !false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOr6 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN false || !false");
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOrInvalid : function () {
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN null || true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN 1 || true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"\" || true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"false\" || true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN [ ] || true"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN { } || true"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || null"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || 1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || \"\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || \"false\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || [ ]"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN true || { }"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN null || false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN 1 || false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"\" || false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN \"false\" || false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN [ ] || false"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN { } || false"); } ));

      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || null"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || 1"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || \"\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || \"false\""); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || [ ]"); } ));
      assertEqual(errors.ERROR_QUERY_INVALID_LOGICAL_VALUE.code, getErrorCode(function() { AHUACATL_RUN("RETURN false || { }"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or, short circuit evaluation
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOrShortCircuit1 : function () {
      // TODO: FIXME                              
      // var expected = [ true ];
      // var actual = getQueryResults("RETURN true || FAIL('this will fail')");
      //assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or, short circuit evaluation
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOrShortCircuit2 : function () {
      assertException(function() { getQueryResults("RETURN false || FAIL('this will fail')"); });
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test binary or, short circuit evaluation
////////////////////////////////////////////////////////////////////////////////
    
    testBinaryOrShortCircuit3 : function () {
      assertException(function() { getQueryResults("RETURN FAIL('this will fail') || true"); });
    },
  };
}

////////////////////////////////////////////////////////////////////////////////
/// @brief executes the test suite
////////////////////////////////////////////////////////////////////////////////

jsunity.run(ahuacatlLogicalTestSuite);

return jsunity.done();

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
