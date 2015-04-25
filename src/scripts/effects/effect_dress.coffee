class Edge
  
  maxLength : 100

  constructor : (@joint) ->
    @geometry = new THREE.Geometry()
    @geometry.vertices = []
    for i in [0...Edge::maxLength]
      @geometry.vertices.push new THREE.Vector3 0,0,0
    @material = new THREE.LineBasicMaterial(color: 0x222222, linewidth:3, linecap:'round')
    @view = new THREE.Line @geometry, @material

  update : (dt) ->
    verts = @geometry.vertices
    v = verts.shift()
    v.x = @joint.x
    v.y = @joint.y
    v.z = @joint.z
    verts.push v
    
    @geometry.verticesNeedUpdate = true


class Ribbon
  
  maxLength : 100

  constructor : (@jts) ->
    @geometry = new THREE.Geometry()
    numJts = @jts.length
    for i in [0...Ribbon::maxLength]
      for j in @jts
        @geometry.vertices.push new THREE.Vector3 j.x, j.y, j.z
    for i in [0...Ribbon::maxLength-1]
      for j in [0...numJts-1]
        @geometry.faces.push new THREE.Face3 i*numJts+j   , i*numJts+j+numJts, i*numJts+j+1        
        @geometry.faces.push new THREE.Face3 i*numJts+j+1 , i*numJts+j+numJts, i*numJts+j+numJts+1

    @geometry.computeFaceNormals()

    @material = new THREE.MeshPhongMaterial
      color: 0x888888
      specular: 0xffffff
      shininess: 50
      side: THREE.DoubleSide
    @view = new THREE.Mesh @geometry, @material

  update : (dt) ->

    verts = @geometry.vertices
    numJts = @jts.length
    for i in [Ribbon::maxLength-1..1]
      for j in [0...numJts]
        verts[i*numJts+j].x = verts[(i-1)*numJts+j].x
        verts[i*numJts+j].y = verts[(i-1)*numJts+j].y
        verts[i*numJts+j].z = verts[(i-1)*numJts+j].z

    for i in [0...numJts]
      verts[i].x = @jts[i].x
      verts[i].y = @jts[i].y
      verts[i].z = @jts[i].z

    @geometry.verticesNeedUpdate = true
    @geometry.normalsNeedUpdate = true
    @geometry.computeFaceNormals()
    @geometry.computeVertexNormals true

    


class TestEffectDress

  constructor : (@body, @scene) ->
    # setDarkTheme()
    @view = new THREE.Object3D
    @ribbons = []
    @edges = []
    # @setupTestSphere()
    @setupLights()
    @setupRibbons()

  setupTestSphere : ->
    material = new THREE.MeshPhongMaterial( { color: 0x555555, specular: 0xffffff, shininess: 50 }  ) 
    radius = 0.1
    geometry = new THREE.SphereGeometry radius, 10,10
    mesh = new THREE.Mesh geometry, material
    mesh.castShadow = true
    @view.add mesh

  setupLights : ->

    ambient = new THREE.AmbientLight 0x9a9a9a
    @scene.add ambient

    sphere = new THREE.SphereGeometry( 0.05, 16, 8 )
    mat = new THREE.MeshBasicMaterial( { color: 0xff0040 } )

    light1 = new THREE.PointLight( 0xffffff, 0.7, 5 )
    light1.position.set 0,0.75,-0.5
    # light1.add new THREE.Mesh( sphere, mat )
    @scene.add light1

    light2 = new THREE.PointLight( 0xffffff, 0.7, 5 )
    light2.position.set 0,0.75,2
    # light2.add new THREE.Mesh( sphere, mat )
    @scene.add light2

  setupRibbons : ->
    return if !@body.joints.length

    list = [
      [
        ks.JointType.LEFT_WRIST
        ks.JointType.LEFT_ELBOW
        ks.JointType.LEFT_SHOULDER
      ], [
        ks.JointType.RIGHT_SHOULDER
        ks.JointType.RIGHT_ELBOW
        ks.JointType.RIGHT_WRIST
      ]
    ]

    for j in list
      arr = []
      arr.push @body.joints[k] for k,i in j
      l = new Ribbon arr
      @view.add l.view
      @ribbons.push l

    for j in list
      e = new Edge @body.joints[j[0]]
      @view.add e.view
      @edges.push e
      e = new Edge @body.joints[j[j.length-1]]
      @view.add e.view
      @edges.push e

  stop : ->
    # ...

  setDebugMode : (debug) ->
    # ...

  update : (dt) ->
    e.update dt for e in @edges
    r.update dt for r in @ribbons


module.exports = TestEffectDress