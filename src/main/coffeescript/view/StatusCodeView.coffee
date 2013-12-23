class StatusCodeView extends Backbone.View
  initialize: ->

  render: ->
    template = @template()
    jQuery(@el).html(template(@model))
    @

  template: ->
    Handlebars.templates.status_code

