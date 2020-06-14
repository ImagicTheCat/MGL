package = "MGL"
version = "scm-1"
source = {
  url = "git://github.com/ImagicTheCat/MGL",
}

description = {
  summary = "Mathematics for Graphics in pure Lua.",
  detailed = [[
  ]],
  homepage = "https://github.com/ImagicTheCat/MGL",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.4"
}

build = {
  type = "builtin",
  modules = {
    MGL = "src/MGL.lua",
    ["MGL.scalar"] = "src/MGL/scalar.lua",
    ["MGL.vector"] = "src/MGL/vector.lua",
    ["MGL.matrix"] = "src/MGL/matrix.lua",
    ["MGL.transform"] = "src/MGL/transform.lua"
  }
}
