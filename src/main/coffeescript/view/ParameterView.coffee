class ParameterView extends Backbone.View
  initialize: ->
    Handlebars.registerHelper 'isArray',
      (param, opts) ->
        if param.type.toLowerCase() == 'array' || param.allowMultiple
          opts.fn(@)
        else
          opts.inverse(@)
          
  render: ->
    type = @model.type || @model.dataType

    if typeof type is 'undefined'
      schema = @model.schema
      if schema and schema['$ref']
        ref = schema['$ref']
        if ref.indexOf('#/definitions/') is 0
          type = ref.substring('#/definitions/'.length)
        else
          type = ref

    @model.type = type
    @model.paramType = @model.in || @model.paramType
    @model.isBody = true if @model.paramType == 'body' or @model.in == 'body'
    @model.isFile = true if type and type.toLowerCase() == 'file'
    @model.default = (@model.default || @model.defaultValue)

    if@model.allowableValues
      @model.isList = true

    template = @template()
    $(@el).html(template(@model))

    signatureModel =
      sampleJSON: @model.sampleJSON
      isParam: true
      signature: @model.signature

    if @model.sampleJSON
      signatureView = new SignatureView({model: signatureModel, tagName: 'div'})
      $('.model-signature', $(@el)).append signatureView.render().el
    else
      $('.model-signature', $(@el)).html(@model.signature)

    isParam = false

    if @model.isBody && @model.schema
      $self = $(@el)
      @model.jsonEditor = 
        new JSONEditor($('.editor_holder', $self)[0],
                       {schema: @model.schema, startval : @model.default, ajax:true })
      # This is so that the signature can send back the sample to the json editor
      # TODO: SignatureView should expose an event "onSampleClicked" instead
      signatureModel.jsonEditor = @model.jsonEditor
      $('.parameter-content-type', $self)
        .change(
          (e) ->
            if e.target.value == "application/xml"
              $('.body-textarea', $self).show()
              $('.editor_holder', $self).hide()
              @model.jsonEditor.disable()
            else
              $('.body-textarea', $self).hide()
              $('.editor_holder', $self).show()
              @model.jsonEditor.enable())
      isParam = true


    if @model.isBody
      isParam = true

    contentTypeModel =
      isParam: isParam

    contentTypeModel.consumes = @model.consumes

    if isParam
      parameterContentTypeView = new ParameterContentTypeView({model: contentTypeModel})
      $('.parameter-content-type', $(@el)).append parameterContentTypeView.render().el

    else
      responseContentTypeView = new ResponseContentTypeView({model: contentTypeModel})
      $('.response-content-type', $(@el)).append responseContentTypeView.render().el

    @

  # Return an appropriate template based on if the parameter is a list, readonly, required
  template: ->
    if @model.isList
      Handlebars.templates.param_list
    else
      if @options.readOnly
        if @model.required
          Handlebars.templates.param_readonly_required
        else
          Handlebars.templates.param_readonly
      else
        if @model.required
          Handlebars.templates.param_required
        else
          Handlebars.templates.param
