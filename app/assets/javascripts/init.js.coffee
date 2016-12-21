
window.App ||= {}

App.init = ->
  App.navigation = new Navigation(".table-notifications")
  $(document).keydown App.navigation.keydown_handler

$(document).ready ->
  App.init()

$(document).on "turbolinks:load", ->
  $('.archive').click ->
    Turbolinks.visit '/notifications/' + $(this).val() + '/archive' + location.search
  $('.unarchive').click ->
    Turbolinks.visit '/notifications/' + $(this).val() + '/unarchive' + location.search
  $('.toggle-star').click ->
    $(this).toggleClass 'star-active star-inactive'
    $.get '/notifications/' + $(this).data('id') + '/star'

$(document).on 'click', '[data-toggle="offcanvas"]', ->
  $('.row-offcanvas').toggleClass 'active'

if !('ontouchstart' of window)
  $ ->
    $('[data-toggle="tooltip"]').tooltip()
