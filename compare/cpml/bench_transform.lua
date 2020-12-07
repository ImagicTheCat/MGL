-- Bench transformation matrix computation for a list of entities.
-- https://github.com/excessive/cpml
local cpml = require("cpml")

local ents, ticks = ...
ents = tonumber(ents) or 1e3
ticks = tonumber(ticks) or 600

local entities = {}
for i=1,ents do
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
for i=1,ticks do
  for _, ent in ipairs(entities) do
    local m = identity()
    scale(m, m, ent.scale)
    rotate(m, m, ent.rotation.z, az)
    rotate(m, m, ent.rotation.y, ay)
    rotate(m, m, ent.rotation.x, ax)
    translate(m, m, ent.position)
    ent.transform = m
  end
end
