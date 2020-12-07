package.path = "src/?.lua"
local mgl = require("MGL")
mgl.gen_mat(2); mgl.gen_vec(2)
mgl.gen_mat(3); mgl.gen_vec(3)
mgl.gen_mat(4); mgl.gen_vec(4)

-- build model matrix
local m = mgl.translate(mgl.vec3(0,0,10)) --
  * mgl.rotate(mgl.vec3(1,0,0), -math.pi/2) --
  * mgl.scale(mgl.vec3(2))
local invm = mgl.inverse(m)
local p = mgl.vec3(0,0,1)
local pp = m*mgl.vec4(p,1)
assert(mgl.vec3(pp) == mgl.vec3(0,2,10))
local ppi = invm*pp
assert(mgl.length(mgl.vec3(ppi)-p) < 1e-6)

local ortho = mgl.orthographic(0,10,0,10,0,10)
assert(ortho*mgl.vec4(5,5,-5,1) == mgl.vec4(0,0,0,1))

local persp = mgl.perspective(math.rad(90), 16/9, 1, 10)
local proj = persp*mgl.vec4(0,0,-5,1)
proj = proj/proj.w
assert(mgl.length(proj-mgl.vec4(0,0,0.5,1)) < 0.3)
local proji = mgl.inverse(persp)*proj
proji = proji/proji.w
assert(mgl.length(proji-mgl.vec4(0,0,0.5,1)) < 1e6)

print("m")
print(m)
print("invm")
print(invm)
print("p", p)
print("pp", pp)
print("ppi", ppi)
print("ortho")
print(ortho)
print("persp")
print(persp)
