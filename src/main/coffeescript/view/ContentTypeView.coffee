class ContentTypeView extends Backbone.View
  initialize: ->

  render: ->
    template = @template()
    jQuery(@el).html(template(@model))

    jQuery('label[for=contentType]', jQuery(@el)).text('Response Content Type')

    @

  template: ->
    Handlebars.templates.content_type

