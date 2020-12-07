-- Bench transformation matrix computation for a list of entities.
package.path = "src/?.lua;../src/?.lua"
local mgl = require("MGL")
mgl.gen_vec(3)
mgl.gen_mat(4); mgl.gen_vec(4)

local ents, ticks = ...
ents = tonumber(ents) or 1e3
ticks = tonumber(ticks) or 600

local entities = {}
for i=1,ents do
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
for i=1,ticks do
  for _, ent in ipairs(entities) do
    ent.transform = translate(ent.position) --
      * rotate(ax, rad(ent.rotation.x))
      * rotate(ay, rad(ent.rotation.y))
      * rotate(az, rad(ent.rotation.z))
      * scale(ent.scale)
  end
end
