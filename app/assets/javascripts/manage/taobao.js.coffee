$(document).bind "page:change ready", ->
  theColorBoxFunction()
  $("a.update_session").click ->
    $(@).colorbox
      href: $(@).attr("href"),
      width:650
      
  $(':checkbox.taobao-all-select').click ->
    checked_val = ($(@).attr('checked') is "checked") ? true : false
    $(':checkbox.taobao-batch-select').attr 'checked', checked_val
    $("input#purchase_products").val("")
    $(':checkbox.taobao-batch-select').each ->
      changeBatchAutoBuyButton $(@)
  
  $(':checkbox.taobao-batch-select').click ->
    changeBatchAutoBuyButton $(@)
      
  $('form#logistic-search').live "ajax:success", (evt, data, status, xhr) ->
    if data isnt false
      $('tbody').empty().append(data)
      theColorBoxFunction()
  
  $("tr.l_taobao_item .button_to[data-remote=true]").live "ajax:success", (evt, data, status, xhr) ->
    order_id_field = $(@).parents('tr').find('td.order_id')
    $(@).replaceWith('<span class="label label-info">已入库</span>')
    if data is true
      order_id_field.find('a').html('可发货').addClass('btn btn-success').attr('target', "_blank")

changeBatchAutoBuyButton = (obj) ->
  old_val = $("input#purchase_products").val().split(',').remove("")
  pp_id = obj.parents('tr').data('id')+""
  if obj.attr('checked') is "checked"
    obj.parents('tr').css('background-color', "#dfd")
    new_val = old_val.add(pp_id)
  else
    obj.parents('tr').css('background-color', "white")
    new_val = old_val.remove(pp_id)
  $("input#purchase_products").val(new_val.join(','))
  
theColorBoxFunction = () ->
  $('a.order_detail').click ->
    $(@).colorbox
      href: $(@).attr("href"),
      width: 650
  
  $('a.pp_taobao_edit').click ->
    ele = $(@)
    $.colorbox
      href: $(@).attr('href'),
      width: 650,
      onComplete: ->
        $("form#purchase button.btn").click ->
          $.colorbox.close()
          return false
        $("form#purchase input.btn").click (e) ->
          $(@).parents('form').ajaxSubmit
            dataType: 'html',
            success: (data) ->
              $.colorbox.close()
              ele.parents('tr').remove()
          return false
    return false