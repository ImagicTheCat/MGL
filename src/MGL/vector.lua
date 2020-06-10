-- https://github.com/ImagicTheCat/MGL
-- MIT license (see LICENSE or MGL.lua)

local unpack = table.unpack or unpack

-- Optimization tip:
-- It seems that the JIT compiler (LuaJIT) can't perform some optimizations in
-- this context when the type metatable is passed as an upvalue to functions
-- taking parameters based on the same metatable.
-- Best to get the metatable directly from the parameters.

-- load
return function(mgl, mglt)
  local generated = {}

  -- Generate vec(D) vector type.
  -- D: dimensions
  function mgl.gen_vec(D)
    if generated[D] then return end -- prevent regeneration
    local mt = mgl.types["vec"..D]

    -- gen: constructor scalars
    do
      local ptypes = {}; for i=1,D do table.insert(ptypes, "number") end
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function($args) return smt({$args}, mt) end
      ]], {args = mglt.genlist("a$", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":constructor_scalars")(mt)
      mgl.defOp(f, "vec"..D, unpack(ptypes))
    end

    -- gen: constructor scalar
    do
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(x) return smt({$xs}, mt) end
      ]], {xs = mglt.genlist("x", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":constructor_scalar")(mt)
      mgl.defOp(f, "vec"..D, "number")
    end

    -- gen: tostring
    do
      local code = mglt.tplsub([[return function(vec) return "("..$cs..")" end]], --
        {cs = mglt.genlist("vec[$]", 1, D, [[..","..]])})
      local f = mglt.genfunc(code, "vec"..D..":tostring")()
      mgl.defOp(f, "tostring", "vec"..D)
    end

    -- gen: add self
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]+b[$]", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":add_vec"..D)()
      mgl.defOp(f, "add", "vec"..D, "vec"..D)
    end

    -- gen: mul self
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*b[$]", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":mul_vec"..D)()
      mgl.defOp(f, "mul", "vec"..D, "vec"..D)
    end

    -- gen: mul number
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(vec, n) return smt({$opl}, gmt(vec)) end
      ]], {opl = mglt.genlist("vec[$]*n", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":mul_number")()
      mgl.defOp(f, "mul", "vec"..D, "number")
    end

    -- gen: mul number alt
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(n, vec) return smt({$opl}, gmt(vec)) end
      ]], {opl = mglt.genlist("vec[$]*n", 1, D)})
      local f = mglt.genfunc(code, "vec"..D..":mul_number_alt")()
      mgl.defOp(f, "mul", "number", "vec"..D)
    end

    generated[D] = true
  end
end
