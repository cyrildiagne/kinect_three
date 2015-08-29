class Joint
  geometry : new THREE.SphereGeometry 0.008
  material : new THREE.MeshBasicMaterial color: 0x0

  constructor : (@id, @joint) ->
    @view = new THREE.Mesh Joint::geometry, Joint::material
    @x = 0
    @y = 0
    @z = 0
    @velocity = new THREE.Vector3()

  set : (@x, @y, @z) ->
    @velocity.x += (@x - @view.position.x - @velocity.x) * 0.05
    @velocity.y += (@y - @view.position.y - @velocity.y) * 0.05
    @velocity.z += (@z - @view.position.z - @velocity.z) * 0.05
    @view.position.x = @x
    @view.position.y = @y
    @view.position.z = @z

# BONE

class Bone
  material : new THREE.LineBasicMaterial(color: 0x0, linewidth:3)

  constructor : (@name, @j1, @j2) ->
    @geometry = new THREE.Geometry()
    @geometry.vertices.push [@j1.x, @j1.y, @j1.z], [@j2.x, @j2.y, @j2.z]
    @view = new THREE.Line @geometry, Bone::material

  update : ->
    v1 = @geometry.vertices[0]
    v1.x = @j1.x
    v1.y = @j1.y
    v1.z = @j1.z
    v2 = @geometry.vertices[1]
    v2.x = @j2.x
    v2.y = @j2.y
    v2.z = @j2.z
    @geometry.verticesNeedUpdate = true

# BODY

class Body
  constructor : (debug) ->
    @view = new THREE.Object3D()
    @bones = []
    @joints = []
    @history = []
    @historyPos = 0
    @historyMaxLength = 60 * 5
    @isLoopingBack = false

  setBody : (@body) ->
    @setupJoints()
    @setupBones()

  setupJoints : () ->
    if @joints.length
      for j,i in @body.joints
        @joints[i].joint = j
    else
      for j,i in @body.joints
        jv = new Joint i, j
        @view.add jv.view
        @joints.push jv
    return

  setupBones : () ->
    if @bones.length
      i = 0
      for k,bone of ks.BoneType
        @bones[i].j1 = @joints[bone[0]]
        @bones[i].j2 = @joints[bone[1]]
        i++
    else
      hidden = [
        'RIGHT_SHOULDER'
        'LEFT_SHOULDER'
        'NECK'
        'LEFT_HIP'
        'RIGHT_HIP'
        'LEFT_THUMB'
        'RIGHT_THUMB'
      ]
      for k,bone of ks.BoneType
        continue if k in hidden
        b = new Bone k, @joints[bone[0]], @joints[bone[1]]
        @view.add b.view
        @bones.push b
    return

  update : (speed=0.5) ->
    if @isLoopingBack
      if ++@historyPos > @history.length-1
        @historyPos = 0
      curr = @history[@historyPos]
      for jnt in @joints
        p = jnt.view.position
        hjnt = curr[jnt.id]
        x = p.x + (  hjnt.x-p.x) * speed
        y = p.y + ( -hjnt.y-p.y) * speed
        z = p.z + ( -1.6+hjnt.z-p.z) * speed
        jnt.set x,y,z
    else
      record = {}
      for jnt in @joints
        p = jnt.view.position
        record[jnt.id] = {x:jnt.joint.x, y:jnt.joint.y, z:jnt.joint.z}
        x = p.x + (  jnt.joint.x-p.x) * speed
        y = p.y + ( -jnt.joint.y-p.y) * speed
        z = p.z + ( -1.6+jnt.joint.z-p.z) * speed
        jnt.set x,y,z
      @history.push record
      if @history.length > @historyMaxLength
        @history.shift()
    bone.update() for bone in @bones

module.exports = Body
