-- Bench transformation matrix computation for a list of entities.
-- https://github.com/excessive/cpml
package.path = package.path..";src/?.lua"
local cpml = require("cpml")

local n = ...
n = tonumber(n) or 1e3

local entities = {}
for i=1,n do
  table.insert(entities, {
    position = cpml.vec3.new(math.random(), math.random(), math.random()),
    rotation = cpml.vec3.new(math.random(), math.random(), math.random()),
    scale = cpml.vec3.new(math.random(), math.random(), math.random())
  })
end

local ax = cpml.vec3.new(1,0,0)
local ay = cpml.vec3.new(0,1,0)
local az = cpml.vec3.new(0,0,1)
local rad = math.rad
local translate = cpml.mat4.translate
local rotate = cpml.mat4.rotate
local scale = cpml.mat4.scale
local identity = cpml.mat4.identity
local start = os.clock()
for i=1,600 do
  for _, ent in ipairs(entities) do
    local m = identity()
    scale(m, m, ent.scale)
    rotate(m, m, ent.rotation.z, az)
    rotate(m, m, ent.rotation.y, ay)
    rotate(m, m, ent.rotation.x, ax)
    translate(m, m, ent.position)
  end
end
local ms = (os.clock()-start)/600*1e3
print("10s of 60 FPS ticks (600) with "..n.." entities: ~"..ms.." ms/tick (~"..math.ceil(ms*6).."% frame)")
