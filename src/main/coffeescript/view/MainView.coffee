class MainView extends Backbone.View
  initialize: ->

  render: ->
    # Render the outer container for resources
    jQuery(@el).html(Handlebars.templates.main(@model))

    # Render each resource
    @addResource resource for resource in @model.apisArray
    @

  addResource: (resource) ->
    # Render a resource and add it to resources li
    resourceView = new ResourceView({model: resource, tagName: 'li', id: 'resource_' + resource.name, className: 'resource'})
    jQuery('#resources').append resourceView.render().el

  clear: ->
    jQuery(@el).html ''