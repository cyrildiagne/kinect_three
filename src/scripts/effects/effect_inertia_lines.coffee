class Line
  
  maxLength : 100

  constructor : (@joint) ->
    
    @geometry = new THREE.Geometry()
    @geometry.vertices = []
    
    for i in [0...Line::maxLength]
      v = new THREE.Vector3 0,0,0
      v.velocity = new THREE.Vector3
      @geometry.vertices.push v

    color = new THREE.Color 0xff0000
    hsl = color.getHSL()
    color.setHSL hsl.h+(Math.random()-0.5)*0.2, hsl.s, hsl.l+(Math.random()-0.5)*0.5
    
    @material = new THREE.LineBasicMaterial(color: color, linewidth:3, linecap:'round')
    @view = new THREE.Line @geometry, @material

  update : (dt) ->

    verts = @geometry.vertices

    fact = 0.9
    for v in verts
      v.x += v.velocity.x * fact
      v.y += v.velocity.y * fact - 0.02
      v.z += v.velocity.z * fact

    v = verts.shift()
    v.x = @joint.x
    v.y = @joint.y
    v.z = @joint.z
    v.velocity = @joint.velocity.clone()
    verts.push v
    
    @geometry.verticesNeedUpdate = true


    

class InertiaLines

  constructor : (@body, @scene) ->
    @view = new THREE.Object3D
    @lines = []
    @setup()

  setup : ->
    return if !@body.joints.length

    for j in @body.joints
      l = new Line j
      @view.add l.view
      @lines.push l

  stop : ->
    # ...

  setDebugMode : (debug) ->
    # ...

  update : (dt) ->
    l.update dt for l in @lines


module.exports = InertiaLines