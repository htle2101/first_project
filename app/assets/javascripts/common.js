jQuery.fn.extend({
  disable: function(){
    return this.each(function(){
      this.disabled = true;
    });
  },
  enable: function(){
    return this.each(function(){
      $(this).removeAttr('disabled');
    });
  }
});

Number.prototype.round = function(place) {
  val = Math.round(this * Math.pow(10, place)) / Math.pow(10, place) + "";
  if (val.indexOf(".") == -1) {
    val += ".";
  }
  for (var i = val.split(".")[1].length; i < place; i += 1) {
    val += "0"
  }
  return val;
}

String.prototype.toFloat = function(){
  return parseFloat(this);
}

String.prototype.toInt = function(){
  return parseInt(this);
}

String.prototype.startWith = function(str){
  return this.indexOf(str) == 0;
};
String.prototype.endWith = function (str){
  return this.slice(-str.length) == str;
};

Array.prototype.hasElement = function(e){
  for(var i = 0; i < this.length; i++) {
    if(this[i] === e)
      return true;
  }
  return false;
}

var Util = function(){
  return {
    isNull: function(value){
      result = false;
      if (value == null || typeof value == "undefined" ) {
        result = true;
      }
      if (result == true) {
        return result;
      }
      if (arguments.length >= 2 && arguments[1] == true) {
        if (value.trim() == "") {
          result = true;
        }else {
          result = false;
        }
      }
      return result;
    },
    isNotNull: function(value) {
      return !Util.isNull.apply(null, arguments);
    },
    required: function(){
      for (var i = 0; i < arguments.length; i++) {
        if (Util.isNull(arguments[i])) {
          return false;
        };
      };
      return true;
    }
  }
}();

function auth_token(){ return $("meta[name='csrf-token']").attr("content"); }


function highlight(element, errorClass) {
  $(element).closest('.control-group').addClass('error');
}
function unhighlight(element, errorClass) {
  $(element).closest('.control-group').removeClass('error');
}
function errorPlacement(error, element) {
  if (element.attr("name") == "captcha"){
    error.addClass('help-inline').insertAfter(element.next());
  }else{
    error.addClass('help-inline').insertAfter(element);
  }
}

$(function() {
  //$("a[rel=popover]").popover();
  $("[rel=tooltip]").tooltip();
  $(document).ajaxSend(function(e, xhr, options) {
    xhr.setRequestHeader("X-CSRF-Token", auth_token());
  });

  $.validator.addMethod("alphanumeric", function(value, element) {
    return this.optional(element) || /^[a-z0-9_]+$/i.test(value);
  }, "Only letters, numbers and underline allowed.");

  $('.delete').live('click', function(){
    if(confirm('Are you sure?')){
      var action = $(this).is('a') ? 'href' : 'act';
      var form = $('<form>').attr({
        action: $(this).attr(action),
        method: 'post'
      }).
        append('<input type="hidden" name="_method" value="delete"/>').
        append('<input type="hidden" name="authenticity_token" value="'+auth_token()+'"/>').hide();
      form.appendTo('body');
      form.submit();
    }
    return false;
  });

  $(".favorite, .favorite-add").sign(function(){
    $(this).toggleClass("button-favorite-active");
    var self = $(this);
    var product_id = $(this).data("id").toString().match(/\d+/)[0];
    var element = $(this).parents("li.list_li").find("div.list_img img");
    var action = self.data("action");
    if (element[0]){
      var pic_url = element.attr("src").replace(/_\d+x\d+.*$/, '')
    }
    if ($('#favorite-loading')[0]){
      $("#favorite-loading").modal({backdrop: 'static'});
    }
    $.post("/favourites/add", {id: product_id, type: self.data("type"), pic_url: pic_url, cid: self.data("cid"), fcid: self.data("fcid"), name:self.data("name"), price: self.data('price') }, function(data){
      if ("products-show products-store products-items".match(action)) self.replaceWith(data);
      $("#favorite-loading").modal('hide');
    }, "text");
  });

  var dp_now = new Date(+new Date()+24*3600000);
  $('.datepicker').live('focus', function(){
    if ($(this).val() == '') $(this).val($(this).attr('data-date'));
    $(this).datepicker({
      format: "yyyy-mm-dd",
      endDate: dp_now.getFullYear()+'-'+(dp_now.getMonth()+1)+'-'+dp_now.getDate(),
      autoclose: true,
      todayHighlight: true
    });
  });

  $("input.pi").live('focus', function(){
    $(this).numeric({ decimal: false, negative: false });
  });

  $("input.pn").live('focus', function(){
    $(this).numeric({ negative: false });
  });

});
