class HeaderView extends Backbone.View
  events: {
    'click #show-pet-store-icon'    : 'showPetStore'
    'click #show-wordnik-dev-icon'  : 'showWordnikDev'
    'click #explore'                : 'showCustom'
    'keyup #input_baseUrl'          : 'showCustomOnKeyup'
    'keyup #input_apiKey'           : 'showCustomOnKeyup'
  }

  initialize: ->

  showPetStore: (e) ->
    @trigger(
      'update-swagger-ui'
      {url:"http://petstore.swagger.wordnik.com/api/api-docs"}
    )

  showWordnikDev: (e) ->
    @trigger(
      'update-swagger-ui'
      {url:"http://api.wordnik.com/v4/resources.json"}
    )

  showCustomOnKeyup: (e) ->
    @showCustom() if e.keyCode is 13

  showCustom: (e) ->
    e?.preventDefault()
    @trigger(
      'update-swagger-ui'
      {url: jQuery('#input_baseUrl').val(), apiKey: jQuery('#input_apiKey').val()}
    )

  update: (url, apiKey, trigger = false) ->
    jQuery('#input_baseUrl').val url
    #jQuery('#input_apiKey').val apiKey
    @trigger 'update-swagger-ui', {url:url} if trigger
