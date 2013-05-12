window.FoxxActiveView = Backbone.View.extend({
  tagName: 'li',
  className: "span3",
  template: new EJS({url: 'js/templates/foxxActiveView.ejs'}),
  
  events: {
    'click .icon-edit': 'editFoxx',
    'click' : 'showDocu'
  },
  
  initialize: function(){
    _.bindAll(this, 'render');
  },
  
  editFoxx: function(event) {
    event.stopPropagation();
    window.App.navigate("application/installed/" + encodeURIComponent(this.model.get("_key")), {trigger: true});
  },
  
  showDocu: function(event) {
    event.stopPropagation();
    window.App.navigate("application/documentation/" + encodeURIComponent(this.model.get("_key")), {trigger: true});
  },
    
  render: function(){
    $(this.el).html(this.template.render(this.model));
    return $(this.el);
  }
});
