////////////////////////////////////////////////////////////////////////////////
/// @brief tests for query language, functions
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

function ahuacatlFunctionsTestSuite () {
  var errors = internal.errors;

////////////////////////////////////////////////////////////////////////////////
/// @brief execute a given query
////////////////////////////////////////////////////////////////////////////////

  function executeQuery (query, bindVars) {
    var cursor = AHUACATL_RUN(query, bindVars);
    if (cursor instanceof ArangoError) {
      print(query, cursor.errorMessage);
    }
    assertFalse(cursor instanceof ArangoError);
    return cursor;
  }

////////////////////////////////////////////////////////////////////////////////
/// @brief execute a given query and return the results as an array
////////////////////////////////////////////////////////////////////////////////

  function getQueryResults (query, isFlat, bindVars) {
    var sanitize = function (row) {
      var keys = [ ];
      for (var k in row) {
        if (row.hasOwnProperty(k) && k != '_rev' && k != '_key' && k != '_id') {
          keys.push(k);
        }
      }

      keys.sort();
      var resultRow = { };
      for (var k in keys) {
        if (keys.hasOwnProperty(k)) {
          resultRow[keys[k]] = row[keys[k]];
        }
      }
      return resultRow;
    };

    var result = executeQuery(query, bindVars).getRows();
    var results = [ ];

    for (var i in result) {
      if (! result.hasOwnProperty(i)) {
        continue;
      }

      var row = result[i];
      if (isFlat) {
        results.push(row);
      } 
      else {
        if (Array.isArray(row)) {
          var x = [ ];
          for (var j = 0; j < row.length; ++j) {
            x.push(sanitize(row[j]));
          }
          results.push(x);
        }
        else {
          results.push(sanitize(row));
        }
      }
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
/// @brief test first require function / expected datatype & arg. mismatch
////////////////////////////////////////////////////////////////////////////////
    
    testContainsFirst : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(\"test\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(\"test\", \"test2\", \"test3\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(null, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(4, 4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS({ }, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(null, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONTAINS(3, null)"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief tear contains true1
////////////////////////////////////////////////////////////////////////////////

    testContainsTrue1 : function () {
      var expected = [true];  
      var actual = getQueryResults("RETURN CONTAINS(\"test2\", \"test\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test contains true2
////////////////////////////////////////////////////////////////////////////////

    testContainsTrue2 : function () {
      var expected = [true];  
      var actual = getQueryResults("RETURN CONTAINS(\"xxasdxx\", \"asd\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test contains false1
////////////////////////////////////////////////////////////////////////////////

    testContainsFalse1 : function () {
      var expected = [false];  
      var actual = getQueryResults("RETURN CONTAINS(\"test\", \"test2\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test contains false2
////////////////////////////////////////////////////////////////////////////////

    testContainsFalse2 : function () {
      var expected = [false];  
      var actual = getQueryResults("RETURN CONTAINS(\"test123\", \"\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test contanis false3
////////////////////////////////////////////////////////////////////////////////

    testContainsFalse3 : function () {
      var expected = [false];  
      var actual = getQueryResults("RETURN CONTAINS(\"\", \"test123\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first function
////////////////////////////////////////////////////////////////////////////////

    testFirst1 : function () {
      var expected = [ { "the fox" : "jumped" } ];
      var actual = getQueryResults("RETURN FIRST([ { \"the fox\" : \"jumped\" }, \"over\", [ \"the dog\" ] ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first function
////////////////////////////////////////////////////////////////////////////////

    testFirst2 : function () {
      var expected = [ "over" ];
      var actual = getQueryResults("RETURN FIRST([ \"over\", [ \"the dog\" ] ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first function
////////////////////////////////////////////////////////////////////////////////

    testFirst3 : function () {
      var expected = [ [ "the dog" ] ];
      var actual = getQueryResults("RETURN FIRST([ [ \"the dog\" ] ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first function
////////////////////////////////////////////////////////////////////////////////

    testFirst4 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first function
////////////////////////////////////////////////////////////////////////////////

    testFirstInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST(4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FIRST({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test last function
////////////////////////////////////////////////////////////////////////////////

    testlast1 : function () {
      var expected = [ [ "the dog" ] ];
      var actual = getQueryResults("RETURN LAST([ { \"the fox\" : \"jumped\" }, \"over\", [ \"the dog\" ] ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test last function
////////////////////////////////////////////////////////////////////////////////

    testlast2 : function () {
      var expected = [ "over" ];
      var actual = getQueryResults("RETURN LAST([ { \"the fox\" : \"jumped\" }, \"over\" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test last function
////////////////////////////////////////////////////////////////////////////////

    testlast3 : function () {
      var expected = [ { "the fox" : "jumped" } ];
      var actual = getQueryResults("RETURN LAST([ { \"the fox\" : \"jumped\" } ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test last function
////////////////////////////////////////////////////////////////////////////////

    testlast4 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN LAST([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test last function
////////////////////////////////////////////////////////////////////////////////

    testlastInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST(4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LAST({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test reverse function
////////////////////////////////////////////////////////////////////////////////

    testReverse1 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN REVERSE([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test reverse function
////////////////////////////////////////////////////////////////////////////////

    testReverse2 : function () {
      var expected = [ [ "fox" ] ];
      var actual = getQueryResults("RETURN REVERSE([ \"fox\" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test reverse function
////////////////////////////////////////////////////////////////////////////////

    testReverse3 : function () {
      var expected = [ [ false, [ "fox", "jumped" ], { "quick" : "brown" }, "the" ] ];
      var actual = getQueryResults("RETURN REVERSE([ \"the\", { \"quick\" : \"brown\" }, [ \"fox\", \"jumped\" ], false ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test reverse function
////////////////////////////////////////////////////////////////////////////////

    testReverseInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE(4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN REVERSE({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUnique1 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN UNIQUE([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUnique2 : function () {
      var expected = [ [ 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, false, true, null, "fox", "FOX", "Fox", "FoX", [0], [1], { "the fox" : "jumped" } ] ];
      var actual = getQueryResults("RETURN UNIQUE([ 1, 2, 3, 4, 5, 6, 7, 8, 9, -1, false, true, null, \"fox\", \"FOX\", \"Fox\", \"FoX\", [ 0 ], [ 1 ], { \"the fox\" : \"jumped\" } ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUnique3 : function () {
      var expected = [ [ 1, 2, 3, 4, 5, 7, 9, 42, -1, -33 ] ];
      var actual = getQueryResults("RETURN UNIQUE([ 1, -1, 1, 2, 3, -1, 2, 3, 4, 5, 1, 3, 9, 2, -1, 9, -33, 42, 7 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUnique4 : function () {
      var expected = [ [ [1, 2, 3], [3, 2, 1], [2, 1, 3], [2, 3, 1], [1, 3, 2], [3, 1, 2] ] ];
      var actual = getQueryResults("RETURN UNIQUE([ [ 1, 2, 3 ], [ 3, 2, 1 ], [ 2, 1, 3 ], [ 2, 3, 1 ], [ 1, 2, 3 ], [ 1, 3, 2 ], [ 2, 3, 1 ], [ 3, 1, 2 ], [ 2 , 1, 3 ] ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUnique5 : function () {
      var expected = [ [ { "the fox" : "jumped" }, { "the fox" : "jumped over" }, { "over" : "the dog", "the fox" : "jumped" }]]

      var actual = getQueryResults("RETURN UNIQUE([ { \"the fox\" : \"jumped\" }, { \"the fox\" : \"jumped over\" }, { \"the fox\" : \"jumped\", \"over\" : \"the dog\" }, { \"over\" : \"the dog\", \"the fox\" : \"jumped\" } ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test unique function
////////////////////////////////////////////////////////////////////////////////

    testUniqueInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE(4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNIQUE({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test length function
////////////////////////////////////////////////////////////////////////////////

    testLength1 : function () {
      var expected = [ 0, 0, 0 ];
      var actual = getQueryResults("FOR year IN [ 2010, 2011, 2012 ] LET quarters = ((FOR q IN [ ] RETURN q)) RETURN LENGTH(quarters)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test length function
////////////////////////////////////////////////////////////////////////////////

    testLength2 : function () {
      var expected = [ 4, 4, 4 ];
      var actual = getQueryResults("FOR year IN [ 2010, 2011, 2012 ] LET quarters = ((FOR q IN [ 1, 2, 3, 4 ] RETURN q)) RETURN LENGTH(quarters)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test length function
////////////////////////////////////////////////////////////////////////////////

    testLength3 : function () {
      var expected = [ 3, 2, 2, 1, 0 ];
      var actual = getQueryResults("FOR test IN [ { 'a' : 1, 'b' : 2, 'c' : null }, { 'baz' : [ 1, 2, 3, 4, 5 ], 'bar' : false }, { 'boom' : { 'bang' : false }, 'kawoom' : 0.0 }, { 'meow' : { } }, { } ] RETURN LENGTH(test)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test length function
////////////////////////////////////////////////////////////////////////////////

    testLengthInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH([ ], [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH(4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LENGTH(\"yes\")"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concat function
////////////////////////////////////////////////////////////////////////////////
    
    testConcat1 : function () {
      var expected = [ "theQuickBrownFoxJumps" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CONCAT('the', 'Quick', '', null, 'Brown', null, 'Fox', 'Jumps')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concat function
////////////////////////////////////////////////////////////////////////////////
    
    testConcat2 : function () {
      var expected = [ "theQuickBrownアボカドJumps名称について" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CONCAT('the', 'Quick', '', null, 'Brown', null, 'アボカド', 'Jumps', '名称について')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concat function
////////////////////////////////////////////////////////////////////////////////

    testConcatInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(\"yes\", true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(\"yes\", 4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(\"yes\", [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(\"yes\", { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(true, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT(4, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT([ ], \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT({ }, \"yes\")"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concatseparator function
////////////////////////////////////////////////////////////////////////////////
    
    testConcatSeparator1 : function () {
      var expected = [ "the,Quick,Brown,Fox,Jumps" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CONCAT_SEPARATOR(',', 'the', 'Quick', null, 'Brown', null, 'Fox', 'Jumps')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concatseparator function
////////////////////////////////////////////////////////////////////////////////
    
    testConcatSeparator2 : function () {
      var expected = [ "the*/*/Quick*/*/Brown*/*/*/*/Fox*/*/Jumps" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CONCAT_SEPARATOR('*/*/', 'the', 'Quick', null, 'Brown', '', 'Fox', 'Jumps')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test concatseparator function
////////////////////////////////////////////////////////////////////////////////

    testConcatSeparatorInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(null, \"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(true, \"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(4, \"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR([ ], \"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR({ }, \"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", true, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", 4, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", [ ], \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", { }, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", \"yes\", true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", \"yes\", 4)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", \"yes\", [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CONCAT_SEPARATOR(\"yes\", \"yes\", { })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test charlength function
////////////////////////////////////////////////////////////////////////////////
    
    testCharLength1 : function () {
      var expected = [ 13 ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CHAR_LENGTH('the quick fox')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test charlength function
////////////////////////////////////////////////////////////////////////////////
    
    testCharLength2 : function () {
      var expected = [ 7 ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CHAR_LENGTH('äöüÄÖÜß')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test charlength function
////////////////////////////////////////////////////////////////////////////////
    
    testCharLength3 : function () {
      var expected = [ 10 ];
      var actual = getQueryResults("FOR r IN [ 1 ] return CHAR_LENGTH('アボカド名称について')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test charlength function
////////////////////////////////////////////////////////////////////////////////

    testCharLengthInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH(\"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH(3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CHAR_LENGTH({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test lower function
////////////////////////////////////////////////////////////////////////////////
    
    testLower1 : function () {
      var expected = [ "the quick brown fox jumped" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return LOWER('THE quick Brown foX JuMpED')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test lower function
////////////////////////////////////////////////////////////////////////////////
    
    testLower2 : function () {
      var expected = [ "äöüäöüß アボカド名称について" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return LOWER('äöüÄÖÜß アボカド名称について')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test lower function
////////////////////////////////////////////////////////////////////////////////
    
    testLower3 : function () {
      var expected = [ "0123456789<>|,;.:-_#'+*@!\"$&/(){[]}?\\" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return LOWER('0123456789<>|,;.:-_#\\'+*@!\\\"$&/(){[]}?\\\\')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test lower function
////////////////////////////////////////////////////////////////////////////////

    testLowerInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER(\"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER(3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN LOWER({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test upper function
////////////////////////////////////////////////////////////////////////////////
    
    testUpper1 : function () {
      var expected = [ "THE QUICK BROWN FOX JUMPED" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return UPPER('THE quick Brown foX JuMpED')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test upper function
////////////////////////////////////////////////////////////////////////////////
    
    testUpper2 : function () {
      var expected = [ "ÄÖÜÄÖÜSS アボカド名称について" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return UPPER('äöüÄÖÜß アボカド名称について')", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test upper function
////////////////////////////////////////////////////////////////////////////////

    testUpperInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER(\"yes\", \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER(3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UPPER({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test substring function
////////////////////////////////////////////////////////////////////////////////
    
    testSubstring1 : function () {
      var expected = [ "the" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return SUBSTRING('the quick brown fox', 0, 3)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test substring function
////////////////////////////////////////////////////////////////////////////////
    
    testSubstring2 : function () {
      var expected = [ "quick" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return SUBSTRING('the quick brown fox', 4, 5)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test substring function
////////////////////////////////////////////////////////////////////////////////
    
    testSubstring3 : function () {
      var expected = [ "fox" ];
      var actual = getQueryResults("FOR r IN [ 1 ] return SUBSTRING('the quick brown fox', -3)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test substring function
////////////////////////////////////////////////////////////////////////////////

    testSubstringInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", 0, 2, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(null, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(true, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(3, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING([ ], 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING({ }, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", null, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", true, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", \"yes\", 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", [ ], 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", { }, 0)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", \"yes\", null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", \"yes\", true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", \"yes\", [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN SUBSTRING(\"yes\", \"yes\", { })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test floor function
////////////////////////////////////////////////////////////////////////////////
    
    testFloor : function () {
      var expected = [ -100, -3, -3, -3, -2, -2, -2, -2, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 3, 99 ];
      var actual = getQueryResults("FOR r IN [ -99.999, -3, -2.1, -2.01, -2, -1.99, -1.1, -1.01, -1, -0.9, -0.6, -0.5, -0.4, -0.1, -0.01, 0, 0.01, 0.1, 0.4, 0.5, 0.6, 0.9, 1, 1.01, 1.1, 1.99, 2, 2.01, 2.1, 3, 99.999 ] return FLOOR(r)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test floor function
////////////////////////////////////////////////////////////////////////////////

    testFloorInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR(1, 2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN FLOOR({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test ceil function
////////////////////////////////////////////////////////////////////////////////
    
    testCeil : function () {
      var expected = [ -99, -3, -2, -2, -2, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 100 ];
      var actual = getQueryResults("FOR r IN [ -99.999, -3, -2.1, -2.01, -2, -1.99, -1.1, -1.01, -1, -0.9, -0.6, -0.5, -0.4, -0.1, -0.01, 0, 0.01, 0.1, 0.4, 0.5, 0.6, 0.9, 1, 1.01, 1.1, 1.99, 2, 2.01, 2.1, 3, 99.999 ] return CEIL(r)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test ceil function
////////////////////////////////////////////////////////////////////////////////

    testCeilInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL(1,2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN CEIL({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test abs function
////////////////////////////////////////////////////////////////////////////////
    
    testAbs : function () {
      var expected = [ 99.999, 3, 2.1, 2.01, 2, 1.99, 1.1, 1.01, 1, 0.9, 0.6, 0.5, 0.4, 0.1, 0.01, 0, 0.01, 0.1, 0.4, 0.5, 0.6, 0.9, 1, 1.01, 1.1, 1.99, 2, 2.01, 2.1, 3, 99.999 ];
      var actual = getQueryResults("FOR r IN [ -99.999, -3, -2.1, -2.01, -2, -1.99, -1.1, -1.01, -1, -0.9, -0.6, -0.5, -0.4, -0.1, -0.01, 0, 0.01, 0.1, 0.4, 0.5, 0.6, 0.9, 1, 1.01, 1.1, 1.99, 2, 2.01, 2.1, 3, 99.999 ] return ABS(r)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test abs function
////////////////////////////////////////////////////////////////////////////////

    testAbsInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS(1,2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ABS({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test round function
////////////////////////////////////////////////////////////////////////////////
    
    testRound : function () {
      var expected = [ -100, -3, -2, -2, -2, -2, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 100 ];
      var actual = getQueryResults("FOR r IN [ -99.999, -3, -2.1, -2.01, -2, -1.99, -1.1, -1.01, -1, -0.9, -0.6, -0.5, -0.4, -0.1, -0.01, 0, 0.01, 0.1, 0.4, 0.5, 0.6, 0.9, 1, 1.01, 1.1, 1.99, 2, 2.01, 2.1, 3, 99.999 ] return ROUND(r)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test round function
////////////////////////////////////////////////////////////////////////////////

    testRoundInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND(1,2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND(true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN ROUND({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test rand function
////////////////////////////////////////////////////////////////////////////////
    
    testRand : function () {
      var actual = getQueryResults("FOR r IN [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ] return RAND()", true);
      for (var i in actual) {
        if (!actual.hasOwnProperty(i)) {
          continue;
        }
        var value = actual[i];
        assertTrue(value >= 0.0 && value < 1.0);
      }
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test rand function
////////////////////////////////////////////////////////////////////////////////

    testRandInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN RAND(1)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN RAND(2)"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge function
////////////////////////////////////////////////////////////////////////////////
    
    testMerge1 : function () {
      var expected = [ { "quarter" : 1, "year" : 2010 }, { "quarter" : 2, "year" : 2010 }, { "quarter" : 3, "year" : 2010 }, { "quarter" : 4, "year" : 2010 }, { "quarter" : 1, "year" : 2011 }, { "quarter" : 2, "year" : 2011 }, { "quarter" : 3, "year" : 2011 }, { "quarter" : 4, "year" : 2011 }, { "quarter" : 1, "year" : 2012 }, { "quarter" : 2, "year" : 2012 }, { "quarter" : 3, "year" : 2012 }, { "quarter" : 4, "year" : 2012 } ]; 
      var actual = getQueryResults("FOR year IN [ 2010, 2011, 2012 ] FOR quarter IN [ 1, 2, 3, 4 ] return MERGE({ \"year\" : year }, { \"quarter\" : quarter })", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge function
////////////////////////////////////////////////////////////////////////////////
    
    testMerge2 : function () {
      var expected = [ { "age" : 15, "isAbove18" : false, "name" : "John" }, { "age" : 19, "isAbove18" : true, "name" : "Corey" } ];
      var actual = getQueryResults("FOR u IN [ { \"name\" : \"John\", \"age\" : 15 }, { \"name\" : \"Corey\", \"age\" : 19 } ] return MERGE(u, { \"isAbove18\" : u.age >= 18 })", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge function
////////////////////////////////////////////////////////////////////////////////
    
    testMerge3 : function () {
      var expected = [ { "age" : 15, "id" : 9, "name" : "John" }, { "age" : 19, "id" : 9, "name" : "Corey" } ];
      var actual = getQueryResults("FOR u IN [ { \"id\" : 100, \"name\" : \"John\", \"age\" : 15 }, { \"id\" : 101, \"name\" : \"Corey\", \"age\" : 19 } ] return MERGE(u, { \"id\" : 9 })", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge function
////////////////////////////////////////////////////////////////////////////////
    
    testMerge4 : function () {
      var expected = [ { "age" : 15, "id" : 33, "name" : "foo" }, { "age" : 19, "id" : 33, "name" : "foo" } ];
      var actual = getQueryResults("FOR u IN [ { \"id\" : 100, \"name\" : \"John\", \"age\" : 15 }, { \"id\" : 101, \"name\" : \"Corey\", \"age\" : 19 } ] return MERGE(u, { \"id\" : 9 }, { \"name\" : \"foo\", \"id\" : 33 })", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge function
////////////////////////////////////////////////////////////////////////////////

    testMergeInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE(null, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE(true, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE(3, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE(\"yes\", { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE([ ], { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, { }, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, { }, true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, { }, 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, { }, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE({ }, { }, [ ])"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive1 : function () {
      var doc1 = "{ \"black\" : { \"enabled\" : true, \"visible\": false }, \"white\" : { \"enabled\" : true}, \"list\" : [ 1, 2, 3, 4, 5 ] }";
      var doc2 = "{ \"black\" : { \"enabled\" : false }, \"list\": [ 6, 7, 8, 9, 0 ] }";

      var expected = [ { "black" : { "enabled" : false, "visible" : false }, "list" : [ 6, 7, 8, 9, 0 ], "white" : { "enabled" : true } } ];

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc2 + ")", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive2 : function () {
      var doc1 = "{ \"black\" : { \"enabled\" : true, \"visible\": false }, \"white\" : { \"enabled\" : true}, \"list\" : [ 1, 2, 3, 4, 5 ] }";
      var doc2 = "{ \"black\" : { \"enabled\" : false }, \"list\": [ 6, 7, 8, 9, 0 ] }";

      var expected = [ { "black" : { "enabled" : true, "visible" : false }, "list" : [ 1, 2, 3, 4, 5 ], "white" : { "enabled" : true } } ];

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc2 + ", " + doc1 + ")", false);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive3 : function () {
      var doc1 = "{ \"a\" : 1, \"b\" : 2, \"c\" : 3 }";

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc1 + ")", false);
      assertEqual([ { "a" : 1, "b" : 2, "c" : 3 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc1 + ", " + doc1 + ")", false);
      assertEqual([ { "a" : 1, "b" : 2, "c" : 3 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc1 + ", " + doc1 + ", " + doc1 + ")", false);
      assertEqual([ { "a" : 1, "b" : 2, "c" : 3 } ], actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive4 : function () {
      var doc1 = "{ \"a\" : 1, \"b\" : 2, \"c\" : 3 }";
      var doc2 = "{ \"a\" : 2, \"b\" : 3, \"c\" : 4 }";
      var doc3 = "{ \"a\" : 3, \"b\" : 4, \"c\" : 5 }";

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc2 + ", " + doc3 + ")", false);
      assertEqual([ { "a" : 3, "b" : 4, "c" : 5 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc3 + ", " + doc2 + ")", false);
      assertEqual([ { "a" : 2, "b" : 3, "c" : 4 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc2 + ", " + doc3 + ", " + doc1 + ")", false);
      assertEqual([ { "a" : 1, "b" : 2, "c" : 3 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc3 + ", " + doc1 + ", " + doc2 + ")", false);
      assertEqual([ { "a" : 2, "b" : 3, "c" : 4 } ], actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive5 : function () {
      var doc1 = "{ \"a\" : 1, \"b\" : 2, \"c\" : 3 }";
      var doc2 = "{ \"1\" : 7, \"b\" : 8, \"y\" : 9 }";
      var doc3 = "{ \"x\" : 4, \"y\" : 5, \"z\" : 6 }";

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc2 + ", " + doc3 + ")", false);
      assertEqual([ { "1" : 7, "a" : 1, "b" : 8, "c" : 3, "x" : 4, "y": 5, "z" : 6 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc3 + ", " + doc2 + ")", false);
      assertEqual([ { "1" : 7, "a" : 1, "b" : 8, "c" : 3, "x" : 4, "y": 9, "z" : 6 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc2 + ", " + doc3 + ", " + doc1 + ")", false);
      assertEqual([ { "1" : 7, "a" : 1, "b" : 2, "c" : 3, "x" : 4, "y": 5, "z" : 6 } ], actual);
      
      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc3 + ", " + doc1 + ", " + doc2 + ")", false);
      assertEqual([ { "1" : 7, "a" : 1, "b" : 8, "c" : 3, "x" : 4, "y": 9, "z" : 6 } ], actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////
    
    testMergeRecursive6 : function () {
      var doc1 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"DE\" : { \"city\" : \"Cologne\" } } } } }";
      var doc2 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"DE\" : { \"city\" : \"Frankfurt\" } } } } }";
      var doc3 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"DE\" : { \"city\" : \"Munich\" } } } } }";
      var doc4 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"UK\" : { \"city\" : \"Manchester\" } } } } }";
      var doc5 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"UK\" : { \"city\" : \"London\" } } } } }";
      var doc6 = "{ \"continent\" : { \"Europe\" : { \"country\" : { \"FR\" : { \"city\" : \"Paris\" } } } } }";
      var doc7 = "{ \"continent\" : { \"Asia\" : { \"country\" : { \"CN\" : { \"city\" : \"Beijing\" } } } } }";
      var doc8 = "{ \"continent\" : { \"Asia\" : { \"country\" : { \"CN\" : { \"city\" : \"Shanghai\" } } } } }";
      var doc9 = "{ \"continent\" : { \"Asia\" : { \"country\" : { \"JP\" : { \"city\" : \"Tokyo\" } } } } }";
      var doc10 = "{ \"continent\" : { \"Australia\" : { \"country\" : { \"AU\" : { \"city\" : \"Sydney\" } } } } }";
      var doc11 ="{ \"continent\" : { \"Australia\" : { \"country\" : { \"AU\" : { \"city\" : \"Melbourne\" } } } } }";
      var doc12 ="{ \"continent\" : { \"Africa\" : { \"country\" : { \"EG\" : { \"city\" : \"Cairo\" } } } } }";

      var actual = getQueryResults("RETURN MERGE_RECURSIVE(" + doc1 + ", " + doc2 + ", " + doc3 + ", " + doc4 + ", " + doc5 + ", " + doc6 + ", " + doc7 + ", " + doc8 + ", " + doc9 + ", " + doc10 + ", " + doc11 + ", " + doc12 + ")", false);

      assertEqual([ { "continent" : { 
        "Europe" : { "country" : { "DE" : { "city" : "Munich" }, "UK" : { "city" : "London" }, "FR" : { "city" : "Paris" } } }, 
        "Asia" : { "country" : { "CN" : { "city" : "Shanghai" }, "JP" : { "city" : "Tokyo" } } }, 
        "Australia" : { "country" : { "AU" : { "city" : "Melbourne" } } }, 
        "Africa" : { "country" : { "EG" : { "city" : "Cairo" } } } 
      } } ], actual);
    },

      
////////////////////////////////////////////////////////////////////////////////
/// @brief test merge_recursive function
////////////////////////////////////////////////////////////////////////////////

    testMergeRecursiveInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE(null, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE(true, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE(3, { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE(\"yes\", { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE([ ], { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, { }, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, { }, true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, { }, 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, { }, \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MERGE_RECURSIVE({ }, { }, [ ])"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test union function
////////////////////////////////////////////////////////////////////////////////
    
    testUnion1 : function () {
      var expected = [ [ 1, 2, 3, 1, 2, 3 ], [ 1, 2, 3, 1, 2, 3 ] ];
      var actual = getQueryResults("FOR u IN [ 1, 2 ] return UNION([ 1, 2, 3 ], [ 1, 2, 3 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test union function
////////////////////////////////////////////////////////////////////////////////
    
    testUnion2 : function () {
      var expected = [ [ 1, 2, 3, 3, 2, 1 ], [ 1, 2, 3, 3, 2, 1 ] ];
      var actual = getQueryResults("FOR u IN [ 1, 2 ] return UNION([ 1, 2, 3 ], [ 3, 2, 1 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test union function
////////////////////////////////////////////////////////////////////////////////
    
    testUnion3 : function () {
      var expected = [ "Fred", "John", "John", "Amy" ];
      var actual = getQueryResults("FOR u IN UNION([ \"Fred\", \"John\" ], [ \"John\", \"Amy\"]) return u", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test union function
////////////////////////////////////////////////////////////////////////////////

    testUnionInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], [ ], null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], [ ], true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], [ ], 3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], [ ], \"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION([ ], [ ], { })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION(null, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION(true, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION(3, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION(\"yes\", [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN UNION({ }, [ ])"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test document function
////////////////////////////////////////////////////////////////////////////////
    
    testDocument1 : function () {
      var cn = "UnitTestsAhuacatlFunctions";

      internal.db._drop(cn);
      var cx = internal.db._create(cn);
      var d1 = cx.save({ "title" : "123", "value" : 456 });
      var d2 = cx.save({ "title" : "nada", "value" : 123 });

      var expected, actual;

      expected = [ { title: "123", value : 456 } ];
      actual = getQueryResults("RETURN DOCUMENT(" + cn + ", \"" + d1._id + "\")", false);
      assertEqual(expected, actual);
      
      expected = [ { title: "nada", value : 123 } ];
      actual = getQueryResults("RETURN DOCUMENT(" + cn + ", \"" + d2._id + "\")", false);
      assertEqual(expected, actual);
      
      internal.db._drop(cn);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test document function
////////////////////////////////////////////////////////////////////////////////
    
    testDocument2 : function () {
      var cn = "UnitTestsAhuacatlFunctions";

      internal.db._drop(cn);
      var cx = internal.db._create(cn);
      var d1 = cx.save({ "title" : "123", "value" : 456, "zxy" : 1 });
      var d2 = cx.save({ "title" : "nada", "value" : 123, "zzzz" : false });

      var expected, actual;

      expected = [ { title: "123", value : 456, zxy: 1 } ];
      actual = getQueryResults("RETURN DOCUMENT(@@cn, @id)", false, { "@cn" : cn, "id" : d1._id });
      assertEqual(expected, actual);
      
      expected = [ { title: "nada", value : 123, zzzz : false } ];
      actual = getQueryResults("RETURN DOCUMENT(@@cn, @id)", false, { "@cn" : cn, "id" : d2._id });
      assertEqual(expected, actual);
      
      internal.db._drop(cn);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test document function
////////////////////////////////////////////////////////////////////////////////
    
    testDocumentMulti1 : function () {
      var cn = "UnitTestsAhuacatlFunctions";

      internal.db._drop(cn);
      var cx = internal.db._create(cn);
      var d1 = cx.save({ "title" : "123", "value" : 456, "zxy" : 1 });
      var d2 = cx.save({ "title" : "nada", "value" : 123, "zzzz" : false });
      var d3 = cx.save({ "title" : "boom", "value" : 3321, "zzzz" : null });

      var expected, actual;

      expected = [ [
        { title: "123", value : 456, zxy : 1 },
        { title: "nada", value : 123, zzzz : false },
        { title: "boom", value : 3321, zzzz : null }
      ] ];

      actual = getQueryResults("RETURN DOCUMENT(@@cn, @id)", false, { "@cn" : cn, "id" : [ d1._id, d2._id, d3._id ] });
      assertEqual(expected, actual);
     
      expected = [ [ { title: "nada", value : 123, zzzz : false } ] ];
      actual = getQueryResults("RETURN DOCUMENT(@@cn, @id)", false, { "@cn" : cn, "id" : [ d2._id ] });
      assertEqual(expected, actual);

      cx.remove(d3);
      
      expected = [ [ { title: "nada", value : 123, zzzz : false } ] ];
      actual = getQueryResults("RETURN DOCUMENT(@@cn, @id)", false, { "@cn" : cn, "id" : [ d2._id, d3._id, "abc/def" ] });
      assertEqual(expected, actual);
      
      internal.db._drop(cn);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test document function
////////////////////////////////////////////////////////////////////////////////
    
    testDocumentInvalid : function () {
      var cn = "UnitTestsAhuacatlFunctions";

      internal.db._drop(cn);
      var cx = internal.db._create(cn);

      var expected, actual;

      // test with non-existing document
      expected = [ ];
      actual = getQueryResults("RETURN DOCUMENT(" + cn + ", \"" + cn + "/99999999999\")", false);
      assertEqual(expected, actual);
      
      actual = getQueryResults("RETURN DOCUMENT(" + cn + ", \"thefoxdoesnotexist/99999999999\")", false);
      assertEqual(expected, actual);

      internal.db._drop(cn);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test min function
////////////////////////////////////////////////////////////////////////////////
    
    testMin1 : function () {
      var expected = [ null, null ]; 
      var actual = getQueryResults("FOR u IN [ [ ], [ null, null ] ] return MIN(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test min function
////////////////////////////////////////////////////////////////////////////////
    
    testMin2 : function () {
      var expected = [ 1, 1, 1, 1, 1, 1 ];
      var actual = getQueryResults("FOR u IN [ [ 1, 2, 3 ], [ 3, 2, 1 ], [ 1, 3, 2 ], [ 2, 3, 1 ], [ 2, 1, 3 ], [ 3, 1, 2 ] ] return MIN(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test min function
////////////////////////////////////////////////////////////////////////////////
    
    testMin3 : function () {
      var expected = [ 2, false, false, false, false, true, -1, '', 1 ];
      var actual = getQueryResults("FOR u IN [ [ 3, 2, '1' ], [ [ ], null, true, false, 1, '0' ], [ '0', 1, false, true, null, [ ] ], [ false, true ], [ 0, false ], [ true, 0 ], [ '0', -1 ], [ '', '-1' ], [ [ ], 1 ] ] return MIN(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test min function
////////////////////////////////////////////////////////////////////////////////

    testMinInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN([ ], 2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN(false)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN(3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MIN({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test max function
////////////////////////////////////////////////////////////////////////////////
    
    testMax1 : function () {
      var expected = [ null, null ]; 
      var actual = getQueryResults("FOR u IN [ [ ], [ null, null ] ] return MAX(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test max function
////////////////////////////////////////////////////////////////////////////////
    
    testMax2 : function () {
      var expected = [ 3, 3, 3, 3, 3, 3 ];
      var actual = getQueryResults("FOR u IN [ [ 1, 2, 3 ], [ 3, 2, 1 ], [ 1, 3, 2 ], [ 2, 3, 1 ], [ 2, 1, 3 ], [ 3, 1, 2 ] ] return MAX(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test max function
////////////////////////////////////////////////////////////////////////////////
    
    testMax3 : function () {
      var expected = [ '1', [ ], [ ], true, 0, 0, '0', '-1', [ ] ];
      var actual = getQueryResults("FOR u IN [ [ 3, 2, '1' ], [ [ ], null, true, false, 1, '0' ], [ '0', 1, false, true, null, [ ] ], [ false, true ], [ 0, false ], [ true, 0 ], [ '0', -1 ], [ '', '-1' ], [ [ ], 1 ] ] return MAX(u)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test max function
////////////////////////////////////////////////////////////////////////////////

    testMaxInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX([ ], 2)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX(null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX(false)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX(3)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX(\"yes\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN MAX({ })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test has function
////////////////////////////////////////////////////////////////////////////////
    
    testHas1 : function () {
      var expected = [ true, true, true, false, true ]; 
      var actual = getQueryResults("FOR u IN [ { \"the fox\" : true }, { \"the fox\" : false }, { \"the fox\" : null }, { \"the FOX\" : true }, { \"the FOX\" : true, \"the fox\" : false } ] return HAS(u, \"the fox\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test has function
////////////////////////////////////////////////////////////////////////////////
    
    testHas2 : function () {
      var expected = [ false, false, false ];
      var actual = getQueryResults("FOR u IN [ { \"the foxx\" : { \"the fox\" : false } }, { \" the fox\" : false }, null ] return HAS(u, \"the fox\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test has function
////////////////////////////////////////////////////////////////////////////////

    testHasInvalid : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ })"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_NUMBER_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, \"fox\", true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS(false, \"fox\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS(3, \"fox\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS(\"yes\", \"fox\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS([ ], \"fox\")"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, null)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, false)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, true)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, 1)"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, [ ])"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_ARGUMENT_TYPE_MISMATCH.code, getErrorCode(function() { AHUACATL_RUN("RETURN HAS({ }, { })"); } ));
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull1 : function () {
      var expected = [ 6 ];
      var actual = getQueryResults("RETURN NOT_NULL(null, 2 + 4)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull2 : function () {
      var expected = [ 6 ];
      var actual = getQueryResults("RETURN NOT_NULL(2 + 4, 2 + 5)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull3 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN NOT_NULL(null, null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull4 : function () {
      var expected = [ 2 ];
      var actual = getQueryResults("RETURN NOT_NULL(2, null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull5 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN NOT_NULL(false, true)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull6 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN NOT_NULL(null, null, null, null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull7 : function () {
      var expected = [ -6 ];
      var actual = getQueryResults("RETURN NOT_NULL(null, null, null, null, -6, -7)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull8 : function () {
      var expected = [ 12 ];
      var actual = getQueryResults("RETURN NOT_NULL(null, null, null, null, 12, null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull9 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN NOT_NULL(null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test not_null
////////////////////////////////////////////////////////////////////////////////
    
    testNotNull10 : function () {
      var expected = [ 23 ];
      var actual = getQueryResults("RETURN NOT_NULL(23)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList1 : function () {
      var expected = [ [ 1, 2 ] ];
      var actual = getQueryResults("RETURN FIRST_LIST(null, [ 1, 2 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList2 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_LIST(null, \"not a list!\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList3 : function () {
      var expected = [ [ 1, 4 ] ];
      var actual = getQueryResults("RETURN FIRST_LIST([ 1, 4 ], [ 1, 5 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList4 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN FIRST_LIST([ ], [ 1, 5 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList5 : function () {
      var expected = [ [ false ] ];
      var actual = getQueryResults("RETURN FIRST_LIST([ false ], [ 1, 5 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList6 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_LIST(false, 7)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList7 : function () {
      var expected = [ [ 0 ] ];
      var actual = getQueryResults("RETURN FIRST_LIST(1, 2, 3, 4, [ 0 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList8 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_LIST(1, 2, 3, 4, { })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList9 : function () {
      var expected = [ [ 7 ] ];
      var actual = getQueryResults("RETURN FIRST_LIST([ 7 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_list
////////////////////////////////////////////////////////////////////////////////
    
    testFirstList10 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_LIST(99)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument1 : function () {
      var expected = [ { a : 1 } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(null, { a : 1 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument2 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(null, \"not a doc!\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument3 : function () {
      var expected = [ { a : 1 } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT({ a : 1 }, { b : 2 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument4 : function () {
      var expected = [ { } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT({ }, { b : 2 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument5 : function () {
      var expected = [ { a : null, b : false } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT({ a : null, b : false }, { a : 1000, b : 1000 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument6 : function () {
      var expected = [ { czz : 7 } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(false, { czz : 7 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument7 : function () {
      var expected = [ { } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(1, 2, 3, 4, { })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument8 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(1, 2, 3, 4, [ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument9 : function () {
      var expected = [ { c : 4 } ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT({ c : 4 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test first_document
////////////////////////////////////////////////////////////////////////////////
    
    testFirstDocument10 : function () {
      var expected = [ null ];
      var actual = getQueryResults("RETURN FIRST_DOCUMENT(false)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool1 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL(null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool2 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL(false)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool3 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(true)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool4 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL(0)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool5 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(0.1)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool6 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(-1)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool7 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(100)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool8 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL(\"\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool9 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(\" \")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool10 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(\"0\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool11 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL(\"false\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool12 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool13 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ 1 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool14 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ false ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool15 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ 0 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool16 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ \"\" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool17 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ \" \" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool18 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ \"0\" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool19 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ \"false\" ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool20 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL([ { } ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool21 : function () {
      var expected = [ false ];
      var actual = getQueryResults("RETURN TO_BOOL({ })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool22 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL({ \"0\" : \"\" })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_bool
////////////////////////////////////////////////////////////////////////////////
    
    testToBool23 : function () {
      var expected = [ true ];
      var actual = getQueryResults("RETURN TO_BOOL({ \"false\" : null })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber1 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER(null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber2 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber3 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER([ 1 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber4 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER([ -1, 1 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber5 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER({ })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber6 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER({ \"2\" : \"3\" })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber7 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER(false)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber8 : function () {
      var expected = [ 1 ];
      var actual = getQueryResults("RETURN TO_NUMBER(true)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber9 : function () {
      var expected = [ 1 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"1\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber10 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"0\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber11 : function () {
      var expected = [ -435.3 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"-435.3\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber12 : function () {
      var expected = [ 3553.4 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"3553.4er6\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber13 : function () {
      var expected = [ 0 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"-wert324\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber14 : function () {
      var expected = [ 143 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"  143\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_number
////////////////////////////////////////////////////////////////////////////////
    
    testToNumber15 : function () {
      var expected = [ 0.4 ];
      var actual = getQueryResults("RETURN TO_NUMBER(\"  .4\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList1 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN TO_LIST(null)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList2 : function () {
      var expected = [ [ false ] ];
      var actual = getQueryResults("RETURN TO_LIST(false)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList3 : function () {
      var expected = [ [ true ] ];
      var actual = getQueryResults("RETURN TO_LIST(true)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList4 : function () {
      var expected = [ [ 35 ] ];
      var actual = getQueryResults("RETURN TO_LIST(35)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList5 : function () {
      var expected = [ [ -0.635 ] ];
      var actual = getQueryResults("RETURN TO_LIST(-0.635)", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList6 : function () {
      var expected = [ [ "" ] ];
      var actual = getQueryResults("RETURN TO_LIST(\"\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList7 : function () {
      var expected = [ [ "value" ] ];
      var actual = getQueryResults("RETURN TO_LIST(\"value\")", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList8 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN TO_LIST({ })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList9 : function () {
      var expected = [ [ 0 ] ];
      var actual = getQueryResults("RETURN TO_LIST({ \"a\" : 0 })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList10 : function () {
      var expected = [ [ null, -63, [ 1, 2 ], { "a" : "b" } ] ];
      var actual = getQueryResults("RETURN TO_LIST({ \"a\" : null, \"b\" : -63, \"c\" : [ 1, 2 ], \"d\": { \"a\" : \"b\" } })", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList11 : function () {
      var expected = [ [ ] ];
      var actual = getQueryResults("RETURN TO_LIST([ ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test to_list
////////////////////////////////////////////////////////////////////////////////
    
    testToList12 : function () {
      var expected = [ [ 0, null, -1 ] ];
      var actual = getQueryResults("RETURN TO_LIST([ 0, null, -1 ])", true);
      assertEqual(expected, actual);
    },

////////////////////////////////////////////////////////////////////////////////
/// @brief test non-existing functions
////////////////////////////////////////////////////////////////////////////////

    testNonExisting : function () {
      assertEqual(errors.ERROR_QUERY_FUNCTION_NAME_UNKNOWN.code, getErrorCode(function() { AHUACATL_RUN("RETURN FOO()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_NAME_UNKNOWN.code, getErrorCode(function() { AHUACATL_RUN("RETURN BAR()"); } ));
      assertEqual(errors.ERROR_QUERY_FUNCTION_NAME_UNKNOWN.code, getErrorCode(function() { AHUACATL_RUN("RETURN PENG(true)"); } ));
    }

  };
}

////////////////////////////////////////////////////////////////////////////////
/// @brief executes the test suite
////////////////////////////////////////////////////////////////////////////////

jsunity.run(ahuacatlFunctionsTestSuite);

return jsunity.done();

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
