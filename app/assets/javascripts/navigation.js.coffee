class window.Navigation
  constructor: (target) ->
    @target = target
    @current = "#{target} td.current"
    @row_index = 1

  current_row: =>
    $(@current).parent()
  
  keydown_handler: (e) =>
    switch e.which
      when 74 # j
        next = @current_row().next()
        if next.length > 0
          $(@current).removeClass 'current'
          $(next).find('td').first().addClass 'current'
          @row_index += 1
      when 75 # k
        prev = @current_row().prev()
        if prev.length > 0
          $(@current).removeClass 'current'
          $(prev).find('td').first().addClass 'current'
          @row_index -= 1
      when 83 # s
        @current_row().find('.toggle-star').click()
      when 89 # y
        @current_row().find('.archive').click()
      when 13 # Enter
        e.preventDefault()
        @current_row().find('.link')[0].click()
      when 191 # ?
        $('#help-box').modal()
      when 190, 82 # . or r
        $('a.sync').click()

  render: ->
    @row_index = Math.min(@row_index, $("#{@target} tr").length)
    @row_index = Math.max(@row_index, 1)
    $("#{@target} tbody tr:nth-child(#{@row_index})").find('td').first().addClass 'current'

$(document).on "turbolinks:load", ->
  App.navigation.render()
