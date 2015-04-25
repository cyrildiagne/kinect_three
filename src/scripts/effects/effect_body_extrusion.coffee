class Ribbon
  
  maxLength : 140

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

    @material = new THREE.MeshNormalMaterial
      color: 0xff0000
      side: THREE.DoubleSide
      
    @view = new THREE.Mesh @geometry, @material
    @view.castShadow = true
    @view.receiveShadow = true

  update : (dt) ->

    verts = @geometry.vertices
    numJts = @jts.length
    for i in [Ribbon::maxLength-1..1]
      for j in [0...numJts]
        verts[i*numJts+j].x = verts[(i-1)*numJts+j].x
        verts[i*numJts+j].y = verts[(i-1)*numJts+j].y
        verts[i*numJts+j].z = verts[(i-1)*numJts+j].z+0.015

    for i in [0...numJts]
      verts[i].x = @jts[i].x
      verts[i].y = @jts[i].y
      verts[i].z = @jts[i].z

    @geometry.verticesNeedUpdate = true
    @geometry.normalsNeedUpdate = true
    @geometry.computeFaceNormals()
    @geometry.computeVertexNormals true

    


class BodyExtrusion

  constructor : (@body, @scene) ->
    @view = new THREE.Object3D
    @lines = []
    # @setupTestSphere()
    @setupLights()
    @setupGround()
    @setupRibbons()

  setupGround : ->
    geometry = new THREE.PlaneBufferGeometry 1600, 1600 
    material = new THREE.MeshPhongMaterial { color:  0xffffff , emissive: 0xbbbbbb } 
    ground = new THREE.Mesh geometry, material 
    ground.position.set 0, -0.86, 0 
    ground.rotation.x = -Math.PI/2
    @scene.add ground 
    ground.receiveShadow = true

  setupTestSphere : ->
    material = new THREE.MeshPhongMaterial { color: 0xff0000, specular: 0x666666, shininess: 8, shading: THREE.SmoothShading } 
    radius = 0.1
    geometry = new THREE.SphereGeometry radius, 10,10
    mesh = new THREE.Mesh geometry, material
    mesh.castShadow = true
    @view.add mesh

  setupLights : ->
    # ambient = new THREE.AmbientLight 0x222222
    ambient = new THREE.AmbientLight 0x6a6a6a
    @scene.add ambient

    light = new THREE.DirectionalLight 0xebf3ff, 1.6
    light.position.set(0, 500, 500).multiplyScalar 1.1
    @scene.add light

    light.castShadow = true

    light.shadowMapWidth = 1024
    light.shadowMapHeight = 2048

    d = 0.1

    light.shadowCameraLeft = -d
    light.shadowCameraRight = d
    light.shadowCameraTop = d * 1.5
    light.shadowCameraBottom = -d

    light.shadowCameraFar = 3500

  setupRibbons : ->
    return if !@body.joints.length

    list = [
      [
        ks.JointType.LEFT_ANKLE
        ks.JointType.LEFT_KNEE
        ks.JointType.LEFT_HIP
        ks.JointType.LEFT_WRIST
        ks.JointType.LEFT_ELBOW
        ks.JointType.LEFT_SHOULDER
        ks.JointType.RIGHT_SHOULDER
        ks.JointType.RIGHT_ELBOW
        ks.JointType.RIGHT_WRIST
        ks.JointType.RIGHT_HIP
        ks.JointType.RIGHT_KNEE
        ks.JointType.RIGHT_ANKLE
      ]
      # [ks.JointType.LEFT_WRIST, ks.JointType.LEFT_ELBOW, ks.JointType.LEFT_SHOULDER]
      # [ks.JointType.RIGHT_SHOULDER, ks.JointType.RIGHT_ELBOW, ks.JointType.RIGHT_WRIST]
    ]

    for j in list
      arr = []
      arr.push @body.joints[k] for k,i in j
      l = new Ribbon arr
      @view.add l.view
      @lines.push l

  stop : ->
    # ...

  setDebugMode : (debug) ->
    # ...

  update : (dt) ->
    l.update dt for l in @lines


module.exports = BodyExtrusion