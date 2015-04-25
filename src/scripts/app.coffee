Body = require './body'
# Playback = require './playback'

fx = {}
fx.TestEffectDress   = require './effects/effect_dress'
fx.TestEffectLines   = require './effects/effect_lines'
fx.TestEffectPhysics = require './effects/effect_physics'
fx.BodyExtrusion     = require './effects/effect_body_extrusion'
fx.InertiaLines      = require './effects/effect_inertia_lines'

class App

	constructor : ->
		@debug = false
		@isPaused = false
		@setupThreejs()
		@setupSkeleton()
		@setupUI()
		@setupDefaults()
		window.addEventListener 'focus', (=> @start()), false
		window.addEventListener 'blur', (=> @stop()), false
		window.addEventListener 'resize', (=> @windowResized()), false
		window.addEventListener 'keydown', @onKeyDown, false

	setupThreejs : ->
		@scene = new THREE.Scene()
		@camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, 0.001, 500
		@camera.position.z = -2
		
		if window.WebGLRenderingContext
			@renderer = new THREE.WebGLRenderer antialias:true
		else
			@renderer = new THREE.CanvasRenderer()
		# @renderer.setClearColor 0x444444, 1
		@renderer.setClearColor 0xffffff, 1
		@renderer.setSize window.innerWidth, window.innerHeight
		@renderer.autoClear = false
		# @renderer.gammaInput = true;
		# @renderer.gammaOutput = true
		# @renderer.shadowMapEnabled = true
		document.body.appendChild @renderer.domElement

		window.setDarkTheme = =>
			$('body').removeClass('light').addClass('dark')
			@renderer.setClearColor 0x222222, 1

		@controls = new THREE.OrbitControls @camera, @renderer.domElement

		@grid = new THREE.GridHelper 3, 0.25
		@grid.position.y -= 0.8
		@scene.add @grid

	setupSkeleton : ->

		@tracker = new ks.Tracker
		@tracker.addListener 'user_in',  @onKinectUserIn
		@tracker.addListener 'user_out', @onKinectUserOut

		@kinectProxy = new ks.Playback @tracker

		@ksview = new ks.DebugView @tracker
		@ksview.proxy = @kinectProxy
		@ksview.canvas.style.position = 'absolute'
		@ksview.canvas.style.right = '0'
		@ksview.canvas.style.bottom = '-30px'

		@body = new Body()
		@scene.add @body.view

	setupUI : ->
		$('#pause').change (ev) =>
			@isPaused = ev.target.checked
			@kinectProxy.togglePlay()
		$('#debug').change (ev) =>
			@setDebugMode ev.target.checked
		$('#file').change (ev) =>
			fileName = $('#file').find('option:selected').val()
			@setPlaybackFile fileName
		$('#effect').change (ev) =>
			effectName = $('#effect').find('option:selected').val()
			@setEffect effectName
		$('#ksvisible').change (ev) =>
			@setKSViewVisible ev.target.checked

	setupDefaults : ->
		effectName = $('#effect').find('option:selected').val()
		@setEffect effectName
		@setDebugMode $('#debug')[0].checked
		fileName = $('#file').find('option:selected').val()
		@setPlaybackFile fileName
		@setKSViewVisible $('#ksvisible')[0].checked

	start : ->
		@animate() if !@animFrameId

	stop : ->
		if @animFrameId
			window.cancelAnimationFrame @animFrameId
			@animFrameId = null

	animate : =>
		@animFrameId = requestAnimationFrame @animate
		@update 1000 / 60
		@controls.update()
		@render()

	update : (dt) ->
		delta = 1000 / 60
		@ksview.render() if @debug
		if !@isPaused
			@body.update()
			@effect.update dt if @effect

	render : ->
		@renderer.clear()
		@renderer.render @scene, @camera
		# if @debug
			# @renderer.clearDepth()
		# @renderer.render @body.scene, @camera

# Kinect Events

	onKinectUserIn : (ev) =>
		return if @tracker.bodies.length != 1
		@body.setBody ev.body
		if @effect
			@setEffect @effect.constructor.name

	onKinectUserOut : (ev) =>
		#destroy current skeleton


# Controls

	setDebugMode : (@debug) ->
		$lis = $('.gui li:not(.always_visible)')
		if @debug 
			$(@ksview.canvas).appendTo($('body'))
			$lis.show()
		else
			$(@ksview.canvas).remove()
			$lis.hide()
		@body.view.visible = @debug
		@effect.setDebugMode @debug if @effect

	setKSViewVisible : (bVisible) ->
		if bVisible
			$(@ksview.canvas).show()
		else
			$(@ksview.canvas).hide()

	setEffect : (effectName) ->
		if @effect
			@effect.stop()
			@scene.remove @effect.view
		EffectClass = fx[effectName]
		if EffectClass
			@effect = new EffectClass @body, @scene
			@scene.add @effect.view

	setPlaybackFile : (fileName) ->
			# @kinectProxy.framerate = 15
			@kinectProxy.play 'assets/kinect/' + fileName + '.json.gz'
		# @kinectProxy.connect "ws://192.168.0.40:9092"

# System Events

	windowResized : (ev) ->
		@camera.aspect = window.innerWidth / window.innerHeight
		@camera.updateProjectionMatrix()
		@renderer.setSize window.innerWidth, window.innerHeight
		@render()

	onKeyDown : (event) =>
		if event.keyCode == 9
			event.preventDefault()
			$('#debug').click()

module.exports = App