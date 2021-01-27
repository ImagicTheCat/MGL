package.path = "src/?.lua;"..package.path
local mgl = require("MGL")
local vec2 = mgl.vec2

local n = ...
n = tonumber(n) or 1e8
print("iterations", n)

local v = vec2(0,0)
for i=1,n do v = v+vec2(1,-1) end
assert(v[1] == n and v[2] == -n)
