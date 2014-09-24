$(document).bind "page:change ready", ->
  # app/views/manage/pages/_form.html.erb

  $('#page_type_id').change ->
    $.get("/manage/page_types/#{$(this).val()}/children", {}, (data) ->
      $('#page_page_type_id').html(data)
    )

  $(".pages.form").validate()

  # app/views/manage/pages/index.html.erb
  $('.page_type_list').click ->
    $('.page_type_list_' + $(this).data('id')).toggle()
    $('.page_type_child_' + $(this).data('id')).toggle()
    $(this).children().first().toggleClass('icon-plus icon-minus')

  $('.expand_all').click ->
    $('.page_type_icon').removeClass('icon-plus')
    $('.page_type_icon').addClass('icon-minus')
    $('.hide_page_type_list').show()
    $('.hide_all').show()
    $(this).hide()

  $('.hide_all').click ->
    $('.page_type_icon').removeClass('icon-minus')
    $('.page_type_icon').addClass('icon-plus')
    $('.hide_page_type_list').hide()
    $('.expand_all').show()
    $(this).hide()


  # app/views/page_types/index.html.erb

  $('.toggle_page_type_children').click ->
    $('.page_type_children_' + $(this).data('id')).toggle()
    $('.page_type_children_flag_' + $(this).data('id')).toggle()

  # app/views/page_types/_form.html.erb

  $('#page_type_parent_id').change ->
    if $(this).val() == ""
      $(".root_fields").show()
    else
      $(".root_fields").hide()

