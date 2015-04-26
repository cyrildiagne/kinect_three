Array.prototype.random = -> @[Math.floor @length*Math.random()]
Array.prototype.last = -> @[@length-1]

document.ontouchmove = (event) -> event.preventDefault()

window.getParam = (sParam) ->
  sPageURL = window.location.search.substring 1
  sURLVariables = sPageURL.split '&'
  for sURLVar in sURLVariables
      sParameterName = sURLVar.split '='
      if sParameterName[0] == sParam
          return sParameterName[1]

window.onload = ->
  App    = require './app'
  app = new App
  app.start()