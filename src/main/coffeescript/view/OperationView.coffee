class OperationView extends Backbone.View
  invocationUrl: null

  events: {
  'submit .sandbox'         : 'submitOperation'
  'click .submit'           : 'submitOperation'
  'click .response_hider'   : 'hideResponse'
  'click .toggleOperation'  : 'toggleOperationContent'
  }

  initialize: ->

  render: ->
    isMethodSubmissionSupported = true #jQuery.inArray(@model.method, @model.supportedSubmitMethods) >= 0
    @model.isReadOnly = true unless isMethodSubmissionSupported

    jQuery(@el).html(Handlebars.templates.operation(@model))

    if @model.responseClassSignature and @model.responseClassSignature != 'string'
      signatureModel =
        sampleJSON: @model.responseSampleJSON
        isParam: false
        signature: @model.responseClassSignature
        
      responseSignatureView = new SignatureView({model: signatureModel, tagName: 'div'})
      jQuery('.model-signature', jQuery(@el)).append responseSignatureView.render().el
    else
      jQuery('.model-signature', jQuery(@el)).html(@model.type)

    contentTypeModel =
      isParam: false

    contentTypeModel.consumes = @model.consumes
    contentTypeModel.produces = @model.produces

    for param in @model.parameters
      type = param.type || param.dataType
      if type.toLowerCase() == 'file'
        if !contentTypeModel.consumes
          console.log "set content type "
          contentTypeModel.consumes = 'multipart/form-data'

    responseContentTypeView = new ResponseContentTypeView({model: contentTypeModel})
    jQuery('.response-content-type', jQuery(@el)).append responseContentTypeView.render().el

    # Render each parameter
    @addParameter param, contentTypeModel.consumes for param in @model.parameters when param.name != 'merchantId'

    # Render each response code
    @addStatusCode statusCode for statusCode in @model.responseMessages

    @

  addParameter: (param, consumes) ->
    # Render a parameter
    param.consumes = consumes
    paramView = new ParameterView({model: param, tagName: 'tr', readOnly: @model.isReadOnly})
    jQuery('.operation-params', jQuery(@el)).append paramView.render().el

  addStatusCode: (statusCode) ->
    # Render status codes
    statusCodeView = new StatusCodeView({model: statusCode, tagName: 'tr'})
    jQuery('.operation-status', jQuery(@el)).append statusCodeView.render().el
  
  submitOperation: (e) ->
    e?.preventDefault()
    # Check for errors
    form = jQuery('.sandbox', jQuery(@el))
    error_free = true
    form.find("input.required").each ->
      jQuery(@).removeClass "error"
      if jQuery.trim(jQuery(@).val()) is ""
        jQuery(@).addClass "error"
        jQuery(@).wiggle
          callback: => jQuery(@).focus()
        error_free = false

    merchantId = jQuery("#input_merchantId").val()
    if jQuery.trim(merchantId) is ""
      jQuery("#input_merchantId").addClass "error"
      jQuery("#input_merchantId").focus()
      jQuery("#input_merchantId").wiggle
        callback: => jQuery("#input_merchantId").focus()
      error_free = false


    # if error free submit it
    if error_free
      map = {}
      opts = {parent: @}

      isFileUpload = false

      for o in form.find("input")
        if(o.value? && jQuery.trim(o.value).length > 0)
          map[o.name] = o.value
        if o.type is "file"
          isFileUpload = true

      for o in form.find("textarea")
        if(o.value? && jQuery.trim(o.value).length > 0)
          map["body"] = o.value

      for o in form.find("select") 
        val = this.getSelectedValue o
        if(val? && jQuery.trim(val).length > 0)
          map[o.name] = val

      map["merchantId"] = merchantId
      opts.responseContentType = jQuery("div select[name=responseContentType]", jQuery(@el)).val()
      opts.requestContentType = jQuery("div select[name=parameterContentType]", jQuery(@el)).val()

      jQuery(".response_throbber", jQuery(@el)).show()
      if isFileUpload
        @handleFileUpload map, form
      else
        @model.do(map, opts, @showCompleteStatus, @showErrorStatus, @)

  success: (response, parent) ->
    parent.showCompleteStatus response

  handleFileUpload: (map, form) ->
    console.log "it's a file upload"
    for o in form.serializeArray()
      if(o.value? && jQuery.trim(o.value).length > 0)
        map[o.name] = o.value

    # requires HTML5 compatible browser
    bodyParam = new FormData()

    # add params
    for param in @model.parameters
      if param.paramType is 'form'
        bodyParam.append(param.name, map[param.name])

    # headers in operation
    headerParams = {}
    for param in @model.parameters
      if param.paramType is 'header'
        headerParams[param.name] = map[param.name]

    console.log headerParams

    # add files
    for el in form.find('input[type~="file"]')
      bodyParam.append(jQuery(el).attr('name'), el.files[0])

    console.log(bodyParam)

    @invocationUrl = 
      if @model.supportHeaderParams()
        headerParams = @model.getHeaderParams(map)
        @model.urlify(map, false)
      else
        @model.urlify(map, true)

    jQuery(".request_url", jQuery(@el)).html "<pre>" + @invocationUrl + "</pre>"

    obj = 
      type: @model.method
      url: @invocationUrl
      headers: headerParams
      data: bodyParam
      dataType: 'json'
      contentType: false
      processData: false
      error: (data, textStatus, error) =>
        @showErrorStatus(@wrap(data), @)
      success: (data) =>
        @showResponse(data, @)
      complete: (data) =>
        @showCompleteStatus(@wrap(data), @)

    # apply authorizations
    if window.authorizations
      window.authorizations.apply obj

    jQuery.ajax(obj)
    false
    # end of file-upload nastiness

  # wraps a jquery response as a shred response  
  wrap: (data) ->
    o = {}
    o.content = {}
    o.content.data = data.responseText
    o.getHeaders = () => {"Content-Type": data.getResponseHeader("Content-Type")}
    o.request = {}
    o.request.url = @invocationUrl
    o.status = data.status
    o

  getSelectedValue: (select) ->
    if !select.multiple 
      select.value
    else
      options = []
      options.push opt.value for opt in select.options when opt.selected
      if options.length > 0 
        options.join ","
      else
        null

  # handler for hide response link
  hideResponse: (e) ->
    e?.preventDefault()
    jQuery(".response", jQuery(@el)).slideUp()
    jQuery(".response_hider", jQuery(@el)).fadeOut()


  # Show response from server
  showResponse: (response) ->
    prettyJson = JSON.stringify(response, null, "\t").replace(/\n/g, "<br>")
    jQuery(".response_body", jQuery(@el)).html escape(prettyJson)

  # Show error from server
  showErrorStatus: (data, parent) ->
    parent.showStatus data

  # show the status codes
  showCompleteStatus: (data, parent) ->
    parent.showStatus data

  # Adapted from http://stackoverflow.com/a/2893259/454004
  formatXml: (xml) ->
    reg = /(>)(<)(\/*)/g
    wsexp = /[ ]*(.*)[ ]+\n/g
    contexp = /(<.+>)(.+\n)/g
    xml = xml.replace(reg, '$1\n$2$3').replace(wsexp, '$1\n').replace(contexp, '$1\n$2')
    pad = 0
    formatted = ''
    lines = xml.split('\n')
    indent = 0
    lastType = 'other'
    # 4 types of tags - single, closing, opening, other (text, doctype, comment) - 4*4 = 16 transitions 
    transitions =
      'single->single': 0
      'single->closing': -1
      'single->opening': 0
      'single->other': 0
      'closing->single': 0
      'closing->closing': -1
      'closing->opening': 0
      'closing->other': 0
      'opening->single': 1
      'opening->closing': 0
      'opening->opening': 1
      'opening->other': 1
      'other->single': 0
      'other->closing': -1
      'other->opening': 0
      'other->other': 0

    for ln in lines
      do (ln) ->

        types =
          # is this line a single tag? ex. <br />
          single: Boolean(ln.match(/<.+\/>/))
          # is this a closing tag? ex. </a>
          closing: Boolean(ln.match(/<\/.+>/))
          # is this even a tag (that's not <!something>)
          opening: Boolean(ln.match(/<[^!?].*>/))

        [type] = (key for key, value of types when value)
        type = if type is undefined then 'other' else type

        fromTo = lastType + '->' + type
        lastType = type
        padding = ''

        indent += transitions[fromTo]
        padding = ('  ' for j in [0...(indent)]).join('')
        if fromTo == 'opening->closing'
          #substr removes line break (\n) from prev loop
          formatted = formatted.substr(0, formatted.length - 1) + ln + '\n'
        else
          formatted += padding + ln + '\n'
      
    formatted
    

  # puts the response data in UI
  showStatus: (data) ->
    content = data.content.data
    headers = data.getHeaders()

    # if server is nice, and sends content-type back, we can use it
    contentType = headers["Content-Type"]

    if content == undefined
      code = jQuery('<code />').text("no content")
      pre = jQuery('<pre class="json" />').append(code)
    else if contentType.indexOf("application/json") == 0 || contentType.indexOf("application/hal+json") == 0
      code = jQuery('<code />').text(JSON.stringify(JSON.parse(content), null, 2))
      pre = jQuery('<pre class="json" />').append(code)
    else if contentType.indexOf("application/xml") == 0
      code = jQuery('<code />').text(@formatXml(content))
      pre = jQuery('<pre class="xml" />').append(code)
    else if contentType.indexOf("text/html") == 0
      code = jQuery('<code />').html(content)
      pre = jQuery('<pre class="xml" />').append(code)
    else if contentType.indexOf("image/") == 0
      pre = jQuery('<img>').attr('src',data.request.url)
    else
      # don't know what to render!
      code = jQuery('<code />').text(content)
      pre = jQuery('<pre class="json" />').append(code)

    response_body = pre
    jQuery(".request_url", jQuery(@el)).html "<pre>" + data.request.url + "</pre>"
    jQuery(".response_code", jQuery(@el)).html "<pre>" + data.status + "</pre>"
    jQuery(".response_body", jQuery(@el)).html response_body
    jQuery(".response_headers", jQuery(@el)).html "<pre>" + JSON.stringify(data.getHeaders(), null, "  ").replace(/\n/g, "<br>") + "</pre>"
    jQuery(".response", jQuery(@el)).slideDown()
    jQuery(".response_hider", jQuery(@el)).show()
    jQuery(".response_throbber", jQuery(@el)).hide()
    hljs.highlightBlock(jQuery('.response_body', jQuery(@el))[0])

  toggleOperationContent: ->
    elem = jQuery('#' + Docs.escapeResourceName(@model.resourceName) + "_" + @model.nickname + "_" + @model.method + "_" + @model.number + "_content")
    if elem.is(':visible') then Docs.collapseOperation(elem) else Docs.expandOperation(elem)
