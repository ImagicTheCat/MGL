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
  local accessors = { -- vector accessors for each component
    {"x", "r"},
    {"y", "g"},
    {"z", "b"},
    {"w", "a"}
  }

  -- Generate vec(D) vector type.
  -- D: dimension
  function mgl.gen_vec(D)
    if generated[D] then return end -- prevent regeneration
    local vtype = "vec"..D
    local mt = mgl.types[vtype]

    -- DATA
    -- gen: getters
    do
      local codes = {}
      for i=1, math.min(D, 4) do
        table.insert(codes, i == 1 and "if " or "elseif ")
        local tests = {}
        for n=1,#accessors[i] do table.insert(tests, "k == \""..accessors[i][n].."\"") end
        table.insert(codes, table.concat(tests, " or "))
        table.insert(codes, " then return t["..i.."]\n")
      end
      table.insert(codes, "end")
      local code = mglt.tplsub([[
return function(t, k)
  $dispatch
end
      ]], {dispatch = table.concat(codes)})
      local f = mglt.genfunc(code, vtype..":get")()
      mt.__index = f
    end

    -- gen: setters
    do
      local codes = {}
      for i=1, math.min(D, 4) do
        table.insert(codes, i == 1 and "if " or "elseif ")
        local tests = {}
        for n=1,#accessors[i] do table.insert(tests, "k == \""..accessors[i][n].."\"") end
        table.insert(codes, table.concat(tests, " or "))
        table.insert(codes, " then t["..i.."] = v\n")
      end
      table.insert(codes, "else rawset(t,k,v) end")
      local code = mglt.tplsub([[
local rawset = rawset
return function(t, k, v)
  $dispatch
end
      ]], {dispatch = table.concat(codes)})
      local f = mglt.genfunc(code, vtype..":set")()
      mt.__newindex = f
    end

    -- gen: copy
    do
      local code = mglt.tplsub([[
return function(a,b)
  $ops
end
      ]], {ops = mglt.genlist("a[$] = b[$]", 1, D, "\n")})
      local f = mglt.genfunc(code, vtype..":copy")()
      mgl.defOp(f, "copy", vtype, vtype)
    end

    -- CONSTRUCTORS
    -- gen: constructor scalars
    do
      local ptypes = {}; for i=1,D do table.insert(ptypes, "number") end
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function($args) return smt({$args}, mt) end
      ]], {args = mglt.genlist("a$", 1, D)})
      local f = mglt.genfunc(code, vtype..":constructor_scalars")(mt)
      mgl.defOp(f, vtype, unpack(ptypes))
    end

    -- gen: constructor scalar
    do
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(x) return smt({$xs}, mt) end
      ]], {xs = mglt.genlist("x", 1, D)})
      local f = mglt.genfunc(code, vtype..":constructor_scalar")(mt)
      mgl.defOp(f, vtype, "number")
    end

    -- gen: constructor list
    do
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(t) return smt({$ts}, mt) end
      ]], {ts = mglt.genlist("t[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":constructor_list")(mt)
      mgl.defOp(f, vtype, "table")
    end

    -- gen: constructors composed
    -- Two elements: vector and vector/scalar.
    -- The first element number of dimensions is always greater than or equal to the second.
    for i=math.max(math.ceil(D/2), 2), D-1 do
      local D1, D2 = i, D-i
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a,b) return smt({$as, $bs}, mt) end
      ]], {
        as = mglt.genlist("a[$]", 1, D1),
        bs = D2 > 1 and mglt.genlist("b[$]", 1, D2) or "b",
      })
      local f = mglt.genfunc(code, vtype..":constructor_composed:"..D1.."+"..D2)(mt)
      mgl.defOp(f, vtype, "vec"..D1, (D2 > 1 and "vec"..D2 or "number"))
    end

    -- gen: constructor truncate
    do
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a) return smt({$as}, mt) end
      ]], {as = mglt.genlist("a[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":constructor_truncate")(mt)
      mgl.defOp(f, vtype, "vec"..(D+1))
    end

    -- gen: constructor copy
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a) return smt({$vs}, gmt(a)) end
      ]], {vs = mglt.genlist("a[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":constructor_copy")()
      mgl.defOp(f, vtype, vtype)
    end

    -- MISC
    -- gen: tostring
    do
      local code = mglt.tplsub([[return function(a) return "("..$cs..")" end]], --
        {cs = mglt.genlist("a[$]", 1, D, [[..","..]])})
      local f = mglt.genfunc(code, vtype..":tostring")()
      mgl.defOp(f, "tostring", vtype)
    end

    -- COMPARISON
    -- gen: equal
    do
      local code = mglt.tplsub([[return function(a, b) return $expr end]], --
        {expr = mglt.genlist("a[$] == b[$]", 1, D, " and ")})
      local f = mglt.genfunc(code, vtype..":equal")()
      mgl.defOp(f, "equal", vtype, vtype)
    end

    -- BASIC ARITHMETIC
    -- gen: unm
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("-a[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":unm")()
      mgl.defOp(f, "unm", vtype)
    end

    -- gen: add
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]+b[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":add")()
      mgl.defOp(f, "add", vtype, vtype)
    end

    -- gen: sub
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]-b[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":sub")()
      mgl.defOp(f, "sub", vtype, vtype)
    end

    -- gen: mul
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*b[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":mul")()
      mgl.defOp(f, "mul", vtype, vtype)
    end

    -- gen: mul number
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, n) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*n", 1, D)})
      local f = mglt.genfunc(code, vtype..":mul_number")()
      mgl.defOp(f, "mul", vtype, "number")
    end

    -- gen: mul number alt
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(n, a) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*n", 1, D)})
      local f = mglt.genfunc(code, vtype..":mul_number_alt")()
      mgl.defOp(f, "mul", "number", vtype)
    end

    -- gen: div
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]/b[$]", 1, D)})
      local f = mglt.genfunc(code, vtype..":div")()
      mgl.defOp(f, "div", vtype, vtype)
    end

    -- gen: div number
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, n) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]/n", 1, D)})
      local f = mglt.genfunc(code, vtype..":div_number")()
      mgl.defOp(f, "div", vtype, "number")
    end

    -- OPERATIONS
    -- gen: length
    do
      local code = mglt.tplsub([[
local sqrt = math.sqrt
return function(a) return sqrt($expr) end
      ]], {expr = mglt.genlist("a[$]*a[$]", 1, D, "+")})
      local f = mglt.genfunc(code, vtype..":length")()
      mgl.defOp(f, "length", vtype)
    end

    -- gen: normalize
    do
      local code = mglt.tplsub([[
local sqrt = math.sqrt
local gmt, smt = getmetatable, setmetatable
return function(a)
  local length = sqrt($length_expr)
  return smt({$opl}, gmt(a)), length
end
      ]], {
        length_expr = mglt.genlist("a[$]*a[$]", 1, D, "+"),
        opl = mglt.genlist("a[$]/length", 1, D)
      })
      local f = mglt.genfunc(code, vtype..":normalize")()
      mgl.defOp(f, "normalize", vtype)
    end

    -- gen: dot
    do
      local code = mglt.tplsub([[
return function(a, b) return $expr end
      ]], {expr = mglt.genlist("a[$]*b[$]", 1, D, "+")})
      local f = mglt.genfunc(code, vtype..":dot")()
      mgl.defOp(f, "dot", vtype, vtype)
    end

    -- gen: cross
    if D == 3 then
      local gmt, smt = getmetatable, setmetatable
      local function f(a, b)
        return smt({
          a[2]*b[3]-a[3]*b[2],
          a[3]*b[1]-a[1]*b[3],
          a[1]*b[2]-a[2]*b[1]
        }, gmt(a))
      end
      mgl.defOp(f, "cross", "vec3", "vec3")
    end

    generated[D] = true
  end
end
