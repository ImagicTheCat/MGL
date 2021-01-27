package.path = "src/?.lua;"..package.path
local mgl = require("MGL")

-- tostring
print(mgl.vec3(1))
do
  -- getters/setters
  local v = mgl.vec4(1)
  v.x, v.y, v.z, v.w = 1,2,3,4
  assert(v == mgl.vec4(1,2,3,4))
  assert(v.x == 1 and v.y == 2 and v.z == 3 and v.w == 4)
  -- copy
  local vc = mgl.vec4(1)
  mgl.copy(vc, v)
  assert(vc == v)
end
-- constructors
assert(mgl.vec2(0) == mgl.vec2(0,0)) -- scalar
assert(mgl.vec4({1,2,3,4}) == mgl.vec4(1,2,3,4)) -- table list
--- generic
assert(mgl.vec10(1, mgl.vec2(2), mgl.vec3(3), mgl.vec4(4)) == mgl.vec10(1,2,2,3,3,3,4,4,4,4))
assert(mgl.vec2(mgl.vec4(1,2,3,4)) == mgl.vec2(1,2)) -- truncation
-- arithmetic/comparison
assert(-mgl.vec2(1) == mgl.vec2(-1)) -- unm
--- add/sub/mul/div
assert(mgl.vec2(1)+mgl.vec2(1)*mgl.vec2(3)-mgl.vec2(1) == mgl.vec2(6)/mgl.vec2(2))
assert(mgl.vec2(1)*2 == 2*mgl.vec2(1)) -- mul number
assert(mgl.vec2(2)/2 == mgl.vec2(1)) -- div number
-- length/normalize
assert(mgl.length(mgl.vec4(4)) == 8)
assert(mgl.length(mgl.normalize(mgl.vec4(4))) == 1)
-- dot/cross
assert(mgl.dot(mgl.vec3(1,2,3), mgl.vec3(4,5,6)) == 32)
assert(mgl.cross(mgl.vec3(1,0,0), mgl.vec3(0,1,0)) == mgl.vec3(0,0,1))
