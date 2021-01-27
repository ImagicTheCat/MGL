-- Bench transformation matrix computation for a list of entities.
package.path = "src/?.lua;../src/?.lua;"..package.path
local mgl = require("MGL")
local tvec3 = mgl.require_vec(3)

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
local translate = mgl.translate:resolve(tvec3)
local rotate = mgl.rotate:resolve(tvec3, "number")
local scale = mgl.scale:resolve(tvec3)
-- Note: the multiplication may also be pre-resolved to slightly increase performances, but is avoided here for readability.
for i=1,ticks do
  for _, ent in ipairs(entities) do
    ent.transform = translate(ent.position) --
      * rotate(ax, rad(ent.rotation.x))
      * rotate(ay, rad(ent.rotation.y))
      * rotate(az, rad(ent.rotation.z))
      * scale(ent.scale)
  end
end
