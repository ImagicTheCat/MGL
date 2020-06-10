package.path = package.path..";src/?.lua"
local mgl = require("MGL")
mgl.gen_vec(2)
local vec2 = mgl.vec2

local n = ...
n = tonumber(n) or 1e8
print("iterations", n)

local v = vec2(0,0)
for i=1,n do v = v+vec2(1,-1) end
v = v*5
print(v)
assert(v[1] == n*5 and v[2] == -n*5)
