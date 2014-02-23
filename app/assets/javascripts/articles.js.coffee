# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$("#autocomplete").autocomplete source: (request, response) ->
  jQuery.ajax
    url: "http://localhost:3000/articles/populate.json"
    dataType: "jsonp"
    data:
      term: request.term

    success: (data) ->
      rows = []
      i = 0

      while i < data.length
        rows.push
          foo: data[i].subject
          value: data[i].subject

        i++
      response rows
      return

  return

