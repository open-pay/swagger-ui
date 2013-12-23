class ResponseContentTypeView extends Backbone.View
  initialize: ->

  render: ->
    template = @template()

    jQuery(@el).html(template(@model))
    
    jQuery('label[for=responseContentType]', jQuery(@el)).text('Response Content Type')

    @

  template: ->
    Handlebars.templates.response_content_type
