class Sku
  constructor: (@id, @default_price, @original_price) ->

  load: (callback) ->
    $.getJSON "/products/#{@id}/skus", (data) =>
      @skus = data
      callback()

  can_select: (pvs) ->
    result = false
    $(@skus).each (i, sku) => 
      if _match(sku.props.split(";"), pvs)
        if sku.stock_num > 0
          result = true
    result


  match: (props) ->
    result = null
    $(@skus).each (i, sku) =>
      entries = sku.props.split ";"
      if _match entries, props
        result = {matched: true, sku_id: sku.sku_id}
        return false
    result ?= {matched: false}

  _match = (entries, props) ->
    result = true
    $(props).each (i, prop) =>
      if !(prop in entries)
        result = false
        return false
    result

window.Sku = Sku
