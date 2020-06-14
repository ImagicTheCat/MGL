package.path = package.path..";src/?.lua"
local mgl = require("MGL")
mgl.gen_vec(4)

local n = ...
n = tonumber(n) or 1e6
print("iterations", n)

local getOp = mgl.getOp
local op
for i=1,n do
  op = getOp("vec4", "number", "number", "number", "number")
end
assert(op)
