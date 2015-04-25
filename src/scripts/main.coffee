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

(->
  ua = navigator.userAgent.toLowerCase()
  if ua.indexOf('firefox') > -1
    window.isFirefox = true
  if ua.indexOf("iphone") > -1 or (ua.indexOf("android") > -1 and ua.indexOf("mobile") > -1)
    window.isMobile = true
    document.write "<meta name=\"viewport\" content=\"initial-scale=1.0,maximum-scale=1.0,user-scalable=no\"" + " />"
)()

window.onload = ->
  App    = require './app'
  app = new App
  app.start()