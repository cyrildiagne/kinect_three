THREE.ShaderTypes =

  celshader:

    uniforms:

      "uDirLightPos":
        type: "v3",
        value: new THREE.Vector3()
      "uDirLightColor":
        type: "c",
        value: new THREE.Color(0xffffff)
      "uMaterialColor":
        type: "c",
        value: new THREE.Color(0xffffff)
      uKd:
        type: "f",
        value: 0.9
      uBorder: 
        type: "f",
        value: 0.4

    vertexShader: [
      "varying vec3 vNormal;"

      "void main() {"

        "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );"
        "vNormal = normalize( normalMatrix * normal );"
        "vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );"

      "}"
    ].join("\n")

    fragmentShader: [

      "uniform vec3 uMaterialColor;"

      "uniform vec3 uDirLightPos;"
      "uniform vec3 uDirLightColor;"

      "uniform float uKd;"
      "uniform float uBorder;"

      "varying vec3 vNormal;"

      "void main() {"

        # compute direction to light
        "vec4 lDirection = viewMatrix * vec4( uDirLightPos, 0.0 );"
        "vec3 lVector = normalize( lDirection.xyz );"

        # diffuse: N * L. Normal must be normalized, since it's interpolated.
        "vec3 normal = normalize( vNormal );"

        "float diffuse = dot( normal, lVector );"
        "if ( diffuse > 0.95 ) { diffuse = 1.0; }"
        "else if ( diffuse > -0.4 ) { diffuse = 0.9; }"
        "else { diffuse = 0.7; }"

        "gl_FragColor = vec4( uKd * uMaterialColor * uDirLightColor * diffuse, 1.0 );"

      "}"

    ].join("\n")


createShaderMaterial = (id, light) ->
  shader = THREE.ShaderTypes[id]
  u = THREE.UniformsUtils.clone shader.uniforms
  vs = shader.vertexShader
  fs = shader.fragmentShader
  material = new THREE.ShaderMaterial
    uniforms: u
    vertexShader: vs
    fragmentShader: fs
  material.uniforms.uDirLightPos.value = light.position
  material.uniforms.uDirLightColor.value = light.color
  return material


class PJoint

  material : null

  constructor : (@joint, @radius=0.15) ->
    @setupView()
    @setupPhysics()

  setupView : ->
    @geometry = new THREE.SphereGeometry @radius, 15, 15
    # @material = new THREE.MeshLambertMaterial color:0x0000ff
    @view = new THREE.Mesh @geometry, PJoint::material

  setupPhysics : ->
    shape = new CANNON.Sphere @radius
    @body = new CANNON.RigidBody 0, shape

  update : (dt) ->
    @view.position.x = @body.position.x = @joint.x
    @view.position.y = @body.position.y = @joint.y
    @view.position.z = @body.position.z = @joint.z




class PBone

  material : null

  constructor : (@bone, @j1, @j2, @radius=0.15) ->
    @setupView()
    @setupPhysics()

  setupView : ->
    @geometry = new THREE.CylinderGeometry @j1.radius, @j2.radius, 0.3
    @geometry.applyMatrix new THREE.Matrix4().makeRotationX( Math.PI/2 )
    @view = new THREE.Mesh @geometry, PBone::material

  setupPhysics : ->
    shape = new CANNON.Cylinder @j1.radius, @j2.radius, 0.3, 6
    @body = new CANNON.RigidBody 0, shape
    @body.position.set (Math.random()-0.5)*0.5, 2, (Math.random()-0.5)*0.5
    @body.quaternion.setFromAxisAngle( new CANNON.Vec3( Math.random(), Math.random(), Math.random() ), Math.random() )

  update : (dt) ->
    j1p = @j1.view.position.clone()
    j2p = @j2.view.position.clone()
    
    # translation
    @view.position.x = @body.position.x = (j1p.x + j2p.x)*0.5
    @view.position.y = @body.position.y = (j1p.y + j2p.y)*0.5
    @view.position.z = @body.position.z = (j1p.z + j2p.z)*0.5

    # scale
    diff = j2p.sub j1p
    length = diff.length()
    @view.scale.z = length/0.3

    # rotation
    @view.lookAt j1p
    @body.quaternion.x = @view.quaternion.x
    @body.quaternion.y = @view.quaternion.y
    @body.quaternion.z = @view.quaternion.z
    @body.quaternion.w = @view.quaternion.w




class PBall

  radius : 0.05

  material : null
  geometry : null

  constructor : (@bone)->
    @pct = Math.random()
    @setupView()
    @setupPhysics()

  setupView : ->
    @view = new THREE.Mesh PBall::geometry, PBall::material

  setupPhysics : ->
    shape = new CANNON.Sphere PBall::radius
    @body = new CANNON.RigidBody 1, shape
    @body.position.set (Math.random()-0.5), (Math.random()-0.5), (Math.random()-0.5)

  update : (dt) ->
    @attractCenter()
    @view.position.x = @body.position.x
    @view.position.y = @body.position.y
    @view.position.z = @body.position.z

  attractCenter : ->
    jpos = new CANNON.Vec3
    jpos.x = @bone.j1.x * (1-@pct) + @bone.j2.x * @pct
    jpos.y = @bone.j1.y * (1-@pct) + @bone.j2.y * @pct
    jpos.z = @bone.j1.z * (1-@pct) + @bone.j2.z * @pct

    bpos = @body.position.copy()
    force = jpos.vsub bpos
    force = force.mult 50
    @body.applyForce force, new CANNON.Vec3 0,0,0
    if @body.velocity.norm() > 0.15
      @body.velocity = @body.velocity.mult 0.95



class TestEffectPhysics

  constructor : (@skeleton) ->
    @view = new THREE.Object3D
    @joints = []
    @bones = []
    @balls = []
    
    @light = new THREE.HemisphereLight 0xffffff, 0x000000, 1
    @light.position.set( -10, 10, 10 )
    @view.add @light

    @setupPhysics()

    @addJoints()
    @addBones()
    @addBalls()
    # @addGround()

  setDebugMode : (debug) ->
    # j.view.visible = debug for j in @joints
    # b.view.visible = debug for b in @bones

  setupPhysics : ->
    @world = new CANNON.World
    @world.gravity.set 0, 0, 0
    @world.broadphase = new CANNON.NaiveBroadphase

  addGround : ->
    groundShape = new CANNON.Plane()
    groundBody = new CANNON.RigidBody 0, groundShape
    groundBody.quaternion.setFromAxisAngle( new CANNON.Vec3(1,0,0), -Math.PI/2 )
    groundBody.position.set 0,-0.5,0
    @world.add groundBody

  addJoints : ->
    color = new THREE.Color 1,1,1
    PJoint::material = createShaderMaterial "celshader", @light
    PJoint::material.uniforms.uMaterialColor.value.copy color

    for j,i in @skeleton.joints
      radius = 0.03
      radius = 0.04 if i in [ks.JointType.LEFT_HIP, ks.JointType.RIGHT_HIP, ks.JointType.LEFT_SHOULDER, ks.JointType.RIGHT_SHOULDER]
      radius = 0.04 if i in [ks.JointType.HEAD]
      # radius = 0.07 if i in [ks.JointType.NECK]
      radius = 0.07 if i in [ks.JointType.SPINE_BASE, ks.JointType.SPINE_MID]
      radius = 0.08 if i in [ks.JointType.SPINE_SHOULDER]
      radius = 0.01 if i in [ks.JointType.LEFT_HAND, ks.JointType.RIGHT_HAND, ks.JointType.LEFT_FOOT, ks.JointType.RIGHT_FOOT]
      pj = new PJoint j, radius
      @view.add pj.view
      @world.add pj.body
      @joints.push pj

  addBones : ->
    # PBone::material = new THREE.MeshLambertMaterial color:0x0000ff
    color = new THREE.Color 1,1,1
    PBone::material = createShaderMaterial "celshader", @light
    PBone::material.uniforms.uMaterialColor.value.copy color

    for b,i in @skeleton.bones
      continue if b.name is 'neck'
      pb = new PBone b, @joints[b.j1.id], @joints[b.j2.id], 0.03
      @view.add pb.view
      @world.add pb.body
      @bones.push pb

  addBalls : ->
    color = new THREE.Color 0, 0, 1
    # color.setHSL 0.8+Math.random()*0.1, 0.7, 0.5
    PBall::material = createShaderMaterial "celshader", @light
    PBall::material.uniforms.uMaterialColor.value.copy color
    PBall::geometry = new THREE.SphereGeometry PBall::radius, 10,10

    for b,i in @bones
      num = 8
      num = 13 if b.bone.name in ['leftUpperLeg', 'rightUpperLeg', 'leftLowerArm', 'rightLowerArm']
      for i in [0...num]
        @addBall b.bone

  addBall : (target) ->
    ball = new PBall target
    @view.add ball.view
    @world.add ball.body
    @balls.push ball

  stop : ->
    #...

  update : (dt) ->
    @world.step 1/60
    j.update dt for j in @joints
    b.update dt for b in @balls
    b.update dt for b in @bones

module.exports = TestEffectPhysics