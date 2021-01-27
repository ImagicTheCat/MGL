package.path = "src/?.lua;"..package.path
local mgl = require("MGL")

do
  -- transform
  --- model matrix
  local m = mgl.translate(mgl.vec3(0,0,10)) --
    * mgl.rotate(mgl.vec3(1,0,0), -math.pi/2) --
    * mgl.scale(mgl.vec3(2))
  local invm = mgl.inverse(m)
  --- transform local point
  local p = mgl.vec3(0,0,1)
  local pt = m*mgl.vec4(p,1)
  assert(mgl.vec3(pt) == mgl.vec3(0,2,10))
  --- inverse transform
  assert(mgl.length(mgl.vec3(invm*pt)-p) < 1e-6)
end
do
  -- projection
  --- othographic
  local ortho = mgl.orthographic(0,10,0,10,0,10)
  assert(ortho*mgl.vec4(5,5,-5,1) == mgl.vec4(0,0,0,1))
  --- perspective
  local persp = mgl.perspective(math.rad(90), 16/9, 1, 10)
  --- project
  local p = mgl.vec4(0,0,-5,1)
  local pt = persp*p
  pt = pt/pt.w
  assert(mgl.length(pt-mgl.vec4(0,0,0.5,1)) < 0.3)
  --- unproject
  local pi = mgl.inverse(persp)*pt
  pi = pi/pi.w
  assert(mgl.length(pi-p) < 1e-6)
end
