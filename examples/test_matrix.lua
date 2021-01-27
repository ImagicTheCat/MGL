package.path = "src/?.lua;"..package.path
local mgl = require("MGL")

-- tostring
print(mgl.mat4(1))
do
  -- vector accessor
  local m = mgl.mat3(1)
  --- get
  assert(m:v(1) == mgl.vec3(1,0,0))
  assert(m:v(2) == mgl.vec3(0,1,0))
  assert(m:v(3) == mgl.vec3(0,0,1))
  --- set
  m:v(1, mgl.vec3(2,0,0))
  m:v(2, mgl.vec3(0,2,0))
  m:v(3, mgl.vec3(0,0,2))
  assert(m == mgl.mat3(2))
  -- copy
  local mc = mgl.mat3(1)
  mgl.copy(mc, m)
  assert(mc == m)
end
-- constructors
assert(mgl.mat2(1) == mgl.mat2({1,0, 0,1})) -- scalar / table list
assert(mgl.mat2(mgl.vec2(1), mgl.vec2(2)) == mgl.mat2({1,2, 1,2})) -- vectors
--- generic
assert(mgl.mat2(mgl.mat4(1)) == mgl.mat2(1)) -- truncation
assert(mgl.mat4(mgl.mat2(1)) == mgl.mat4(1)) -- extension
-- arithmetic/comparison
assert(-mgl.mat2(1)+mgl.mat2(1)-mgl.mat2(1) == -mgl.mat2(1)) -- unm/add/sub
assert(mgl.mat2(1)*2 == 2*mgl.mat2(1)) -- mul number
assert(mgl.mat2(1)/2 == mgl.mat2(1/2)) -- div number
--- generic
assert(mgl.mat2(1)*mgl.mat2(1) == mgl.mat2(1)) -- square mat/mat
assert(mgl.mat2x3(1)*mgl.mat3x2(1) == mgl.mat3({1,0,0, 0,1,0, 0,0,0})) -- mat/mat
assert(mgl.mat4(1)*mgl.vec4(2) == mgl.vec4(2)) -- mat/vec
-- transpose
assert(mgl.transpose(mgl.mat4(1)) == mgl.mat4(1))
assert(mgl.transpose(mgl.mat3x2(1)) == mgl.mat2x3(1))
-- determinant/inverse
assert(mgl.determinant(mgl.mat2(1)) == 1)
assert(mgl.determinant(mgl.mat3(1)) == 1)
assert(mgl.determinant(mgl.mat4(1)) == 1)
assert(mgl.inverse(mgl.mat2(1))*mgl.mat2(1) == mgl.mat2(1))
assert(mgl.inverse(mgl.mat3(1))*mgl.mat3(1) == mgl.mat3(1))
assert(mgl.inverse(mgl.mat4(1))*mgl.mat4(1) == mgl.mat4(1))
