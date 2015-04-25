class TestEffectLine
  
  maxLength : 25

  constructor : (@joint) ->
    @geometry = new THREE.Geometry()
    @geometry.vertices = []
    for i in [0...TestEffectLine::maxLength]
      @geometry.vertices.push new THREE.Vector3(0, 0, 0)

    color = new THREE.Color 0x0000ff
    hsl = color.getHSL()
    color.setHSL hsl.h, hsl.s, hsl.l+(Math.random()-0.5)*0.5
    @material = new THREE.LineBasicMaterial(color: color, linewidth:10, linecap:'round')
    
    @view = new THREE.Line @geometry, @material


  update : (dt) ->

    for v in @geometry.vertices
      v.x += 0.03
    
    verts = @geometry.vertices
    verts.push new THREE.Vector3(@joint.x-0.35, @joint.y, @joint.z)
    if verts.length > TestEffectLine::maxLength
      verts.shift()

    @geometry.verticesNeedUpdate = true


class TestEffectLines

  constructor : (@skeleton) ->
    @view = new THREE.Object3D
    @lines = []
    for j in @skeleton.joints
      l = new TestEffectLine j
      @view.add l.view
      @lines.push l

  stop : ->
    # ...

  setDebugMode : (debug) ->
    # ...

  update : (dt) ->
    l.update dt for l in @lines


module.exports = TestEffectLines