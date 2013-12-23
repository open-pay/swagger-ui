class ParameterContentTypeView extends Backbone.View
  initialize: ->

  render: ->
    template = @template()
    jQuery(@el).html(template(@model))

    jQuery('label[for=parameterContentType]', jQuery(@el)).text('Parameter content type:')

    @

  template: ->
    Handlebars.templates.parameter_content_type

