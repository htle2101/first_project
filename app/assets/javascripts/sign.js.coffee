jQuery.fn.sign = (success_do) ->
  self = null
  $(this).live 'click', ->
    self = $(this)
    if $(this).hasClass("no")
      ajax_to_login()
    else
      if (Util.isNotNull(success_do) && typeof success_do == 'function') then success_do.call(self[0])

  ajax_to_login = ->
    $.colorbox
      href: '/user/sign',
      width: 600
      onComplete: ->
        $(".sign-tab li").click -> 
          $(this).siblings().removeClass("able").end().addClass("able")
          rel = "#" + $(this).attr "rel"
          $("form.form-horizontal").hide()
          $("form.form-horizontal" + rel).show()
          $.colorbox.resize()
        $("#a-sub").live 'click', ->
          $(this).parents('form:first').validate
            errorElement: 'span',
            messages: message(this),
            errorPlacement: errorPlacement,
            highlight: highlight,
            unhighlight: unhighlight,
            submitHandler: (form) -> 
              $(form).ajaxSubmit
                success: (data) -> if data.user then success_submit(data) else password_error(form, data),
                error: -> alert("Error")

  password_error = (form, data) ->
    error = '<span for="user_password" generated="true" class="error help-inline">' + data + '</span>'
    if $(form).attr("id") == "signup-form"
      alert("Error")
    else
      element = $(form).find("#user_password")
      element.parents(".control-group").addClass("error")
      if element.next("span.error")[0]
        element.next("span.error").show().end().next("span.error").text(data)
      else
        element.after(error)

  message = (element) ->
    remote_message = "Account does not exist."
    if $(element).parents("form").attr("id") == "signup-form"
      remote_message = "This Email has been used."
    messages = {
      'user[email]': {
        email: "Enter a valid email.",
        remote: remote_message
      },
      'user[name]': {
        remote: "This nickname has been used."
      },
      'user[password]':{
        minlength: "Minimum is 6 characters."
      },
      'user[password_confirmation]':{
        minlength: "Minimum is 6 characters.",
        equalTo: "Please enter the same value."
      },
      'captcha': {
        remote: "The verification code is incorrect."
      }
    }
      

  window.highlight = (element, errorClass) -> $(element).closest('.control-group').addClass('error')

  window.unhighlight = (element, errorClass) -> $(element).closest('.control-group').removeClass('error')

  window.errorPlacement = (error, element) ->  
    if element.attr("name") == "captcha"
      error.addClass('help-inline').insertAfter(element.next());
    else
      error.addClass('help-inline').insertAfter(element);

  success_submit = (data) -> 
    if Util.isNotNull(data)
      $('.sign-area').replaceWith(data.user)
      $('.cart-link b').text(data.cart)
      $.colorbox.close()
      $(".no").removeClass("no")
      if (Util.isNotNull(success_do) && typeof success_do == 'function') then success_do.call(self[0])
