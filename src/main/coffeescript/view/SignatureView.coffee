class SignatureView extends Backbone.View
  events: {
  'click a.description-link'       : 'switchToDescription'
  'click a.snippet-link'           : 'switchToSnippet'
  'mousedown .snippet'          : 'snippetToTextArea'
  }

  initialize: ->

  render: ->
    template = @template()
    jQuery(@el).html(template(@model))

    @switchToDescription()

    @isParam = @model.isParam

    if @isParam
      jQuery('.notice', jQuery(@el)).text('Click to set as parameter value')

    @

  template: ->
      Handlebars.templates.signature

  # handler for show signature
  switchToDescription: (e) ->
    e?.preventDefault()
    jQuery(".snippet", jQuery(@el)).hide()
    jQuery(".description", jQuery(@el)).show()
    jQuery('.description-link', jQuery(@el)).addClass('selected')
    jQuery('.snippet-link', jQuery(@el)).removeClass('selected')
    
  # handler for show sample
  switchToSnippet: (e) ->
    e?.preventDefault()
    jQuery(".description", jQuery(@el)).hide()
    jQuery(".snippet", jQuery(@el)).show()
    jQuery('.snippet-link', jQuery(@el)).addClass('selected')
    jQuery('.description-link', jQuery(@el)).removeClass('selected')

  # handler for snippet to text area
  snippetToTextArea: (e) ->
    if @isParam
      e?.preventDefault()
      textArea = jQuery('textarea', jQuery(@el.parentNode.parentNode.parentNode))
      if jQuery.trim(textArea.val()) == ''
        textArea.val(@model.sampleJSON)


    
