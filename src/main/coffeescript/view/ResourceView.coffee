class ResourceView extends Backbone.View
  initialize: ->

  render: ->
    console.log @model.description
    jQuery(@el).html(Handlebars.templates.resource(@model))

    @number = 0

    # Render each operation
    @addOperation operation for operation in @model.operationsArray
    @

  addOperation: (operation) ->

    operation.number = @number

    # Render an operation and add it to operations li
    operationView = new OperationView({model: operation, tagName: 'li', className: 'endpoint'})
    jQuery('.endpoints', jQuery(@el)).append operationView.render().el

    @number++