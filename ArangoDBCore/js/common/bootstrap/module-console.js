/*jslint indent: 2, nomen: true, maxlen: 100, sloppy: true, vars: true, white: true, plusplus: true */
/*global Module */

////////////////////////////////////////////////////////////////////////////////
/// @brief module "console"
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
/// @author Dr. Frank Celler
/// @author Copyright 2010-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// --SECTION--                                                  Module "console"
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @addtogroup V8ModuleConsole
/// @{
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// @brief console module
////////////////////////////////////////////////////////////////////////////////

(function () {
  var internal = Module.prototype.ModuleCache["/internal"].exports;
  var console = Module.prototype.ModuleCache["/console"].exports;

  console.getline = internal.getline;

////////////////////////////////////////////////////////////////////////////////
/// @brief logs debug message
///
/// @FUN{console.debug(@FA{format}, @FA{argument1}, ...)}
///
/// Formats the arguments according to @FA{format} and logs the result as
/// debug message.
///
/// String substitution patterns, which can be used in @FA{format}.
///
/// - @LIT{\%s} string
/// - @LIT{\%d}, @LIT{\%i} integer
/// - @LIT{\%f} floating point number
/// - @LIT{\%o} object hyperlink
////////////////////////////////////////////////////////////////////////////////

  console.debug = function () {
    var msg;

    try {
      msg = internal.sprintf.apply(internal.sprintf, arguments);
    }
    catch (err) {
      msg = err + ": " + arguments;
    }

    internal.log("debug", msg);
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief logs error message
///
/// @FUN{console.error(@FA{format}, @FA{argument1}, ...)}
///
/// Formats the arguments according to @FA{format} and logs the result as
/// error message.
////////////////////////////////////////////////////////////////////////////////

  console.error = function () {
    var msg;

    try {
      msg = internal.sprintf.apply(internal.sprintf, arguments);
    }
    catch (err) {
      msg = err + ": " + arguments;
    }

    internal.log("error", msg);
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief logs info message
///
/// @FUN{console.info(@FA{format}, @FA{argument1}, ...)}
///
/// Formats the arguments according to @FA{format} and logs the result as
/// info message.
////////////////////////////////////////////////////////////////////////////////

  console.info = function () {
    var msg;

    try {
      msg = internal.sprintf.apply(internal.sprintf, arguments);
    }
    catch (err) {
      msg = err + ": " + arguments;
    }

    internal.log("info", msg);
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief logs log message
///
/// @FUN{console.log(@FA{format}, @FA{argument1}, ...)}
///
/// Formats the arguments according to @FA{format} and logs the result as
/// log message.
////////////////////////////////////////////////////////////////////////////////

  console.log = function () {
    var msg;

    try {
      msg = internal.sprintf.apply(internal.sprintf, arguments);
    }
    catch (err) {
      msg = err + ": " + arguments;
    }

    internal.log("info", msg);
  };

////////////////////////////////////////////////////////////////////////////////
/// @brief logs warn message
///
/// @FUN{console.warn(@FA{format}, @FA{argument1}, ...)}
///
/// Formats the arguments according to @FA{format} and logs the result as
/// warn message.
////////////////////////////////////////////////////////////////////////////////

  console.warn = function () {
    var msg;

    try {
      msg = internal.sprintf.apply(internal.sprintf, arguments);
    }
    catch (err) {
      msg = err + ": " + arguments;
    }

    internal.log("warning", msg);
  };

////////////////////////////////////////////////////////////////////////////////
/// @}
////////////////////////////////////////////////////////////////////////////////

}());

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "^\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @}\\)"
// End:
