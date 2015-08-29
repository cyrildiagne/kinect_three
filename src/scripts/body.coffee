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



class Body

  constructor : (debug) ->
    # @scene = new THREE.Scene()
    @view = new THREE.Object3D()
    # @scene.add @view
    @bones = []
    @joints = []

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
      for k,bone of ks.BoneType
        b = new Bone k, @joints[bone[0]], @joints[bone[1]]
        @view.add b.view
        @bones.push b
    return

  setData : (@data) ->
    # ...

  toString : () ->
    str = ""
    for i in [0...@data.length] by 3
      str += "#{i/3} - #{@data[i]} - #{@data[i+1]}" + '\n'
    return str

  update : (speed=0.5) ->
    # console.log @joints[0].joint.x
    for jnt in @joints
      p = jnt.view.position
      x = p.x + (  jnt.joint.x*1.000-p.x) * speed
      y = p.y + ( -jnt.joint.y*1.000-p.y) * speed
      z = p.z + ( -1.6+jnt.joint.z*1.000-p.z) * speed
      jnt.set x,y,z

      bone.update() for bone in @bones

module.exports = Body