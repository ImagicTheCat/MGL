-- Bench transformation matrix computation for a list of entities.
package.path = package.path..";src/?.lua"
local mgl = require("MGL")
mgl.gen_vec(3)
mgl.gen_mat(4); mgl.gen_vec(4)

local n = ...
n = tonumber(n) or 1e3

local entities = {}
for i=1,n do
  table.insert(entities, {
    position = mgl.vec3(math.random(), math.random(), math.random()),
    rotation = mgl.vec3(math.random(), math.random(), math.random()),
    scale = mgl.vec3(math.random(), math.random(), math.random())
  })
end

local ax = mgl.vec3(1,0,0)
local ay = mgl.vec3(0,1,0)
local az = mgl.vec3(0,0,1)
local rad = math.rad
local translate = mgl.getOp("translate", "vec3")
local rotate = mgl.getOp("rotate", "vec3", "number")
local scale = mgl.getOp("scale", "vec3")
local start = os.clock()
for i=1,600 do
  for _, ent in ipairs(entities) do
    ent.transform = translate(ent.position) --
      * rotate(ax, rad(ent.rotation.x))
      * rotate(ay, rad(ent.rotation.y))
      * rotate(az, rad(ent.rotation.z))
      * scale(ent.scale)
  end
end
local ms = (os.clock()-start)/600*1e3
print("10s of 60 FPS ticks (600) with "..n.." entities: ~"..ms.." ms/tick (~"..math.ceil(ms*6).."% frame)")
