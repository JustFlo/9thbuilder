//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require jquery.ui.touch-punch
//= require jquery.formalize
//= require jquery.colorbox

//= require bootstrap

jQuery(function($) {

  $('#header .welcome strong').click(function() {
    $(this).toggleClass('over');
    $('#header .menu').css('width', $(this).css('width')).toggle();
  });

  $('#header .welcome .lang').click(function() {
    $(this).toggleClass('over');
    $('#header .menu-lang').toggle( "slow" );
  });

  $('body').click(function(evt) {
    $('#header .menu').hide();
    $('#header .welcome strong').removeClass('over')
  });

  $('#header').click(function(evt){
    evt.stopPropagation();
  });

  $('body').on('click', 'button[data-url]:not([data-popin])', function(evt) {
    evt.preventDefault();

    var url = $(this).data('url'),
        params = $(this).data('params') || null;

    if (params) {
      url = url + '?' + params;
    }

    if ($(this).data('target') == '_blank') {
      window.open(url);
    }
    else {
      window.location = url;
    }
  });

  $('body').on('click', 'a[data-popin], button[data-popin]', popinHandler);
  $('body').on('submit', 'form[data-popin]', popinHandler);
  $('body').on('change', 'input[name=include_magics]', function() {
    var checked = $(this).prop('checked'),
        $popin  = $(this).closest('.popin');

    $popin.find('button[data-url]').each(function() {
      if (checked) {
        $(this).data('url', $(this).data('url').replace('_nomagics', '_magics'));
      }
      else {
        $(this).data('url', $(this).data('url').replace('_magics', '_nomagics'));
      }
    });
  });

  $('.army_list_units_overview')
    .sortable({
      handle: '.position',
      update: function(event, ui) {
        $.post($(this).data('url'), $(this).sortable('serialize'), function() {
          $('.army_list_units_overview .position').each(function(index) {
            $(this).html(index < 9 ? '0' + (index+1) : index+1);
          });
        });
      }
    })
  ;

  $('body').on('click', '.army_list_unit_overview .name', function() {
    $(this).closest('.army_list_unit_overview').next('.army_list_unit_details').slideToggle('fast');
  });

  $('body').on('change', '.army_list_unit_overview .actions select, #subheader .actions select', function() {
    $(this).closest('form').attr('action', $(this).val());
  });

  $('body').on('click', '#army_list_unit_magic_items ul li strong', function() {
    $('#army_list_unit_magic_items ul li ul').not($(this).next('ul')).slideUp('fast');
    $(this).next('ul').slideToggle('fast', function() { $.colorbox.resize(); });
  });

  $('body').on('click', '#army_list_unit_extra_items ul li strong', function() {
    $('#army_list_unit_extra_items ul li ul').not($(this).next('ul')).slideUp('fast');
    $(this).next('ul').slideToggle('fast', function() { $.colorbox.resize(); });
  });

  $('body').on('change', '#army_list_unit_unit_options input, #army_list_unit_magic_items input, #army_list_unit_extra_items input, #army_list_unit_magic_standards input', function(evt) {
    var total     = 0.0,
        $changed  = $(this),
        $siblings = $changed.closest('ul').find('> li > label input[data-radio]').not($changed),
        $div      = $changed.closest('div');

    $div.find('input[type=number]').prop('disabled', true);

    if ($div.attr('id') == 'army_list_unit_magic_items') {
      $div.find('strong').css('opacity', 0.5);
    }

    if ($div.attr('id') == 'army_list_unit_extra_items') {
      $div.find('strong').css('opacity', 0.5);
    }

    $div.find('input:checked').each(function() {
      $(this).parent('label').next('input').prop('disabled', false);
      $(this).closest('ul').prev('strong').css('opacity', 1);

      var value_points = parseFloat($(this).parent('label').prev('em').find('span').html().replace(',', '.'));

      var $quantity = $(this).parent('label').next('input[type=number]');

      if ($quantity.length) {
        value_points = value_points * parseInt($quantity.val());
      }

      if ($div.data('value-points-limit')) {
        if (total + value_points > parseFloat($div.data('value-points-limit'))) {
          $changed.prop('checked', false);
          $quantity.val('');
          updateArmyListUnitDepend($changed);
          evt.stopPropagation();
          return false;
        }
      }

      total += value_points;
    });

    if (evt.isPropagationStopped()) {
      return false;
    }

    if ($changed.data('radio') && $changed.prop('checked')) {
      $siblings.prop('checked', false).each(function() {
        updateArmyListUnitDepend($(this));
      });
    }

    updateArmyListUnitDepend($changed);

    updateArmyListUnitValuePoints();
  });

  $('body').on('keyup', '.edit_army_list_unit #army_list_unit_troops .army_list_unit_troop_size', function() {
    var size = parseInt($(this).val());

    var minSize = parseInt($(this).closest('tr').data('min-size')),
        maxSize = parseInt($(this).closest('.popin').find('h1').data('max-size'));

    if (isNaN(minSize)) {
      minSize = parseInt($(this).closest('.popin').find('h1').data('min-size'));
    }

    if (isNaN(size) || size < minSize || (!isNaN(maxSize) && size > maxSize)) {
      return false;
    }

    if ($(this).attr('id') == 'army_list_unit_army_list_unit_troops_attributes_0_size') {
      $('#army_list_unit_unit_options input[data-per-model]').each(function() {
        var value_points = size * parseFloat($(this).data('value-points'));

        $(this).parent('label').prev('em').find('span').html(String(value_points).replace('.', ','));
        $(this).parent('label').next('input').val(size);
      });
    }

    updateArmyListUnitValuePoints();
  });

  $('body').on('keyup', '.edit_army_list_unit #army_list_unit_unit_options .army_list_unit_unit_option_quantity', function() {
    var quantity = parseInt($(this).val());

    if (isNaN(quantity)) return false;

    var value_points = quantity * parseFloat($(this).prev('label').find('input[data-is-multiple]').data('value-points'));

    $(this).prev('label').prev('em').find('span').html(String(value_points).replace('.', ','));

    updateArmyListUnitValuePoints();
  });

});

function updateArmyListUnitDepend($changed)
{
  var $master = $changed.is('input[name$="[_destroy]"]') ? $changed.closest('li').find('> input[name$="[unit_option_id]"]') : $changed,
      $slaves = $('.edit_army_list_unit input[data-depend='+$master.val()+']');

  if ($changed.prop('checked')) {
    $slaves.attr('disabled', false);
  }
  else {
    $slaves.prop('disabled', true).prop('checked', false).each(function() {
      updateArmyListUnitDepend($(this));
    });
  }
}

function updateArmyListUnitValuePoints()
{
  $('#army_list_unit_unit_options, #army_list_unit_magic_items, #army_list_unit_extra_items, #army_list_unit_magic_standards').each(function() {
    var total = 0.0,
        $div  = $(this);

    $div.find('input:checked').each(function() {
      var value_points = parseFloat($(this).parent('label').prev('em').find('span').html().replace(',', '.'));

      var $quantity = $(this).parent('label').next('input[name$="[quantity]"]');

      if ($quantity.length) {
        value_points = parseFloat($(this).data('value-points')) * parseInt($quantity.val());

        if (isNaN(value_points)) {
          return true;
        }
      }

      total += value_points;
    });

    $div.find('h3 span').html(String(total).replace('.', ','));
  });

  var total  = 0.0,
      $popin = $('.popin');

  if ($('#army_list_unit_troops').length) {
    $('#army_list_unit_troops tr').each(function() {
      var size              = parseInt($(this).find('.army_list_unit_troop_size').val()),
          value_points      = parseFloat($(this).data('value-points')),
          min_size          = parseInt($popin.find('h1').data('min-size')),
          unit_value_points = parseFloat($popin.find('h1').data('value-points'));

      if (isNaN(size)) return;

      if (isNaN(value_points)) {
        total += size * unit_value_points;
      }
      else {
        total += Math.ceil(min_size * unit_value_points);
        total += (size - min_size) * value_points;
      }
    });
  }
  else {
    total = parseFloat($popin.find('h1').data('value-points'));
  }

  if ($('#army_list_unit_unit_options').length) {
    total += parseFloat($('#army_list_unit_unit_options h3 span').html().replace(',', '.'));
  }

  if ($('#army_list_unit_magic_items').length) {
    total += parseFloat($('#army_list_unit_magic_items h3 span').html().replace(',', '.'));
  }

  if ($('#army_list_unit_extra_items').length) {
    total += parseFloat($('#army_list_unit_extra_items h3 span').html().replace(',', '.'));
  }

  if ($('#army_list_unit_magic_standards').length) {
    total += parseFloat($('#army_list_unit_magic_standards h3 span').html().replace(',', '.'));
  }

  $popin.find('h1 span').html(String(total).replace('.', ','));
}

function popinHandler(evt)
{
  evt.preventDefault();

  var $this = $(this),
      url;

  if ($this.is('a')) {
    url = $this.attr('href');
  }
  else if ($this.is('form')) {
    url = $(this).attr('action');
  }
  else if ($this.is('[data-url]')) {
    url = $(this).data('url');
  }

  popin(url);
}

function popin(url)
{
  $.colorbox({
    href: url,
    close: '',
    opacity: 0.4,
    returnFocus: false,
    scrolling: false,
    onComplete: function() {
      $('#cboxClose').css('opacity', 1);
      $('#cboxLoadedContent form :input:visible:first').focus();

      var masters = [];
      $('#army_list_unit_unit_options input[data-depend], #army_list_unit_magic_items input[data-depend], #army_list_unit_extra_items input[data-depend], #army_list_unit_magic_standards input[data-depend]').each(function() {
        var selector = '#army_list_unit_unit_option_ids_' + $(this).data('depend');

        if ($.inArray(selector, masters) < 0) {
          masters.push(selector);
        }
      });

      $(masters.join(', ')).change();

      $('#army_list_unit_magic_items input:first').change();
      $('#army_list_unit_extra_items input:first').change();
    },
    onClosed: function() {
      $('#cboxClose').css('opacity', 0);
    }
  });
}
