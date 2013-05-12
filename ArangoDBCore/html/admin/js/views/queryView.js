var queryView = Backbone.View.extend({
  el: '#content',
  initialize: function () {
    localStorage.setItem("queryContent", "");
    localStorage.setItem("queryOutput", "");
  },
  events: {
    'click #submitQueryIcon'   : 'submitQuery',
    'click #submitQueryButton' : 'submitQuery',
    'click .clearicon': 'clearOutput',
  },
  clearOutput: function() {
    $('#queryOutput').empty();
  },

  template: new EJS({url: 'js/templates/queryView.ejs'}),

  render: function() {

    $(this.el).html(this.template.text);
    var editor = ace.edit("aqlEditor");
    var editor2 = ace.edit("queryOutput");

    editor2.setReadOnly(true);
    editor2.setHighlightActiveLine(false);

    editor.getSession().setMode("ace/mode/aql");
    editor2.getSession().setMode("ace/mode/json");
    editor.setTheme("ace/theme/merbivore_soft");
    editor2.setValue('');

    $('#queryOutput').resizable({
      handles: "s",
      ghost: true,
      stop: function () {
        var editor2 = ace.edit("queryOutput");
        editor2.resize();
      }
    });
    $('#aqlEditor').resizable({
      handles: "s",
      ghost: true,
      //helper: "resizable-helper",
      stop: function () {
        var editor = ace.edit("aqlEditor");
        editor.resize();
      }
    });

    $('#aqlEditor .ace_text-input').focus();
    $.gritter.removeAll();

    if(typeof(Storage)!=="undefined") {
      var queryContent = localStorage.getItem("queryContent");
      var queryOutput = localStorage.getItem("queryOutput");
      editor.setValue(queryContent);
      editor2.setValue(queryOutput);
    }

    var windowHeight = $(window).height() - 250;
    $('#queryOutput').height(windowHeight/2);
    $('#aqlEditor').height(windowHeight/2);

    editor.resize();
    editor2.resize();

    return this;
  },
  submitQuery: function() {
    var self = this;
    var editor = ace.edit("aqlEditor");
    var data = {query: editor.getValue()};

    var editor2 = ace.edit("queryOutput");

    $.ajax({
      type: "POST",
      url: "/_api/cursor",
      data: JSON.stringify(data),
      contentType: "application/json",
      processData: false,
      success: function(data) {
        editor2.setValue(self.FormatJSON(data.result));
        if(typeof(Storage) !== "undefined") {
          localStorage.setItem("queryContent", editor.getValue());
          localStorage.setItem("queryOutput", editor2.getValue());
        }
      },
      error: function(data) {
        try {
          var temp = JSON.parse(data.responseText);
          editor2.setValue('[' + temp.errorNum + '] ' + temp.errorMessage);

          if(typeof(Storage) !== "undefined") {
            localStorage.setItem("queryContent", editor.getValue());
            localStorage.setItem("queryOutput", editor2.getValue());
          }
        }
        catch (e) {
          editor2.setValue('ERROR');
        }
      }
    });
    editor2.resize();

  },
  FormatJSON: function(oData, sIndent) {
    var self = this;
    if (arguments.length < 2) {
      var sIndent = "";
    }
    var sIndentStyle = "    ";
    var sDataType = self.RealTypeOf(oData);

    if (sDataType == "array") {
      if (oData.length == 0) {
        return "[]";
      }
      var sHTML = "[";
    } else {
      var iCount = 0;
      $.each(oData, function() {
        iCount++;
        return;
      });
      if (iCount == 0) { // object is empty
        return "{}";
      }
      var sHTML = "{";
    }

    // loop through items
    var iCount = 0;
    $.each(oData, function(sKey, vValue) {
      if (iCount > 0) {
        sHTML += ",";
      }
      if (sDataType == "array") {
        sHTML += ("\n" + sIndent + sIndentStyle);
      } else {
        sHTML += ("\n" + sIndent + sIndentStyle + JSON.stringify(sKey) + ": ");
      }

      // display relevant data type
      switch (self.RealTypeOf(vValue)) {
        case "array":
          case "object":
          sHTML += self.FormatJSON(vValue, (sIndent + sIndentStyle));
        break;
        case "boolean":
          case "number":
          sHTML += vValue.toString();
        break;
        case "null":
          sHTML += "null";
        break;
        case "string":
          sHTML += "\"" + vValue.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
        break;
        default:
          sHTML += ("TYPEOF: " + typeof(vValue));
      }

      // loop
      iCount++;
    });

    // close object
    if (sDataType == "array") {
      sHTML += ("\n" + sIndent + "]");
    } else {
      sHTML += ("\n" + sIndent + "}");
    }

    // return
    return sHTML;
  },
  RealTypeOf: function(v) {
    if (typeof(v) == "object") {
      if (v === null) return "null";
      if (v.constructor == (new Array).constructor) return "array";
      if (v.constructor == (new Date).constructor) return "date";
      if (v.constructor == (new RegExp).constructor) return "regex";
      return "object";
    }
    return typeof(v);
  }

});
