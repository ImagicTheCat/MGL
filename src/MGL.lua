-- https://github.com/ImagicTheCat/MGL
-- MIT license (see LICENSE or MGL.lua)

--[[
MIT License

Copyright (c) 2020 ImagicTheCat

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- MGL tools.

local loadstring = loadstring or load
local type, getmetatable = type, getmetatable

-- Generate function.
-- name: identify the generated function for debug
local function mglt_genfunc(code, name)
  local f, err = loadstring(code, "MGL generated "..name)
  if not f then error(err) end
  return f
end

-- Generate "a1, a2, a3, a4..." list string.
-- t_element: string where "$" will be replaced by the element index
-- a: start index
-- b: end index
-- separator: (optional) default: ", "
local function mglt_genlist(t_element, a, b, separator)
  local args = {}
  for i=a,b do
    local element = string.gsub(t_element, "%$", i)
    table.insert(args, element)
  end
  return table.concat(args, separator or ", ")
end

-- Template substitution.
-- template: string with $... parameters
-- args: map of param => value
-- return processed template
local function mglt_tplsub(template, args)
  return string.gsub(template, "%$([%w_]+)", args)
end

-- MGL interface/data.

local mgl
-- return MGL type (table-based type name or Lua type)
local function mgl_type(v) return getmetatable(v) and getmetatable(v).MGL_type or type(v) end

-- Format prototype for debug.
-- id: operator id
-- ...: parameter types
local function format_proto(id, ...)
  local types = {}
  for i, p in ipairs({...}) do table.insert(types, p) end
  return id.."("..table.concat(types, ", ")..")"
end

-- Format call prototype for debug.
-- id: operator id
-- ...: arguments
local function format_call(id, ...)
  local types = {}
  for i, arg in ipairs({...}) do table.insert(types, mgl_type(arg)) end
  return id.."("..table.concat(types, ", ")..")"
end

-- Operator prototypes.
-- Registered functions taking parameters of specific types.
-- Map of operator id => nested tables. Each level contains parameter types as key
-- with t[1] as the final function and t[2] as the op table index.
local ops = {}
local opst = {} -- ops table, list/indexed op functions
local ops_callbacks = {}

-- Listen to operator definitions.
-- callback(mgl, op): called when an operator definition changes (prototype update)
--- mgl: MGL handle
--- op: operator id
local function listenOps(callback)
  ops_callbacks[callback] = true
end

-- Unlisten from operator definitions.
-- callback: previously registered callback
local function unlistenOps(callback)
  ops_callbacks[callback] = nil
end

local function publishOps(id)
  for cb in pairs(ops_callbacks) do cb(mgl, id) end
end

-- Define operator prototype function.
-- It will replace the previous prototype function if identical.
-- Calling this function will mark the operator for update (old references will
-- work, but without the updated behavior).
--
-- func(...): called with operands
-- ...: strings, operator id and prototype (parameter types)
--- parameter types: MGL types or special types ("*": any non-nil)
local function defOp(func, ...)
  local args = {...}
  -- prevent definition of non-operators
  if rawget(mgl, args[1]) and not ops[args[1]] then error("cannot define operator "..args[1]) end

  local t = ops
  for i, p in ipairs(args) do
    local nt = t[p]
    if not nt then nt = {}; t[p] = nt end
    t = nt
  end
  table.insert(opst, func)
  t[1], t[2] = func, #opst
  mgl[args[1]] = nil -- mark operator for update
  publishOps(args[1]) -- call ops listeners
end

local getop_funcs = {} -- map of params count => func

-- Get operator prototype function.
-- ...: strings, operator id and prototype (parameter types)
-- return function or falsy if not found / invalid
local function getOp(...)
  local n = select("#", ...)
  local f = getop_funcs[n]
  if not f then
    local code = mglt_tplsub([[return function(ops, $args) return ops$targs[1] end]], {
      args = mglt_genlist("a$", 1, n),
      targs = mglt_genlist("[a$]", 1, n, "")
    })
    f = mglt_genfunc(code, "getOp#"..n)()
    getop_funcs[n] = f
  end
  local ok, op = pcall(f, ops, ...)
  return ok and op
end

-- Generate dispatch conditions/call (recursive).
-- return (code, max_depth)
local function gen_op_dispatch(t, depth)
  if not depth then depth = 0 end
  local max_depth = depth
  local codes = {}
  local first = true
  local any_st
  for stype, st in pairs(t) do -- each subtype/subtable
    if type(stype) == "string" then
      if stype == "*" then any_st = st -- special parameter type: any
      else -- regular type
        local scode, sdepth = gen_op_dispatch(st, depth+1)
        max_depth = math.max(max_depth, sdepth)
        if #scode > 0 then
          -- gen: open/continue condition
          table.insert(codes, (first and "if" or "elseif").." at"..(depth+1).." == \""..stype.."\" then\n")
          table.insert(codes, scode) -- subcode
          first = false
        end
      end
    end
  end
  if not first or any_st then -- gen: nil/any check condition
    -- gen: nil check condition (prevent silent mistake)
    table.insert(codes, (first and "if" or "elseif").." at"..(depth+1).." ~= \"nil\" then\n")
    if any_st then -- gen: any branch
      local scode, sdepth = gen_op_dispatch(any_st, depth+1)
      max_depth = math.max(max_depth, sdepth)
      table.insert(codes, scode)
    end
    first = false
  end
  if t[1] then -- gen: op call
    if not first then table.insert(codes, "else\n") end
    table.insert(codes, "return opst["..t[2].."]("..mglt_genlist("a$", 1, depth)..")\n")
  end
  if not first then table.insert(codes, "end\n") end -- gen: close condition
  return table.concat(codes), max_depth
end

-- Generate operator function.
-- id: operator id
-- return operator function or nothing if not defined
local function gen_op(id)
  local t = ops[id]
  if t then
    local dcode, depth = gen_op_dispatch(t)
    local code = mglt_tplsub([[
local id, opst, mgl_type, format_call = ...
return function($args)
  local $argst = $types
  do
    $dispatch
  end
  error("invalid operator prototype "..format_call(id $sep $args))
end
    ]], {
      args = mglt_genlist("a$", 1, depth),
      argst = mglt_genlist("at$", 1, depth),
      types = mglt_genlist("mgl_type(a$)", 1, depth),
      dispatch = dcode,
      sep = depth > 0 and "," or ""
    })
    return mglt_genfunc(code, "op:"..id)(id, opst, mgl_type, format_call)
  end
end

-- map of op id => metamethod {key, func}
local op_metamethods = {}

-- return metamethod function
local function gen_op_metamethod(op)
  return mgl[op]
end

-- MGL types metatable pool.
-- Accessing a nil field will create the type.
-- map of MGL type => metatable
local types = {}
setmetatable(types, {
  __index = function(types, k)
    -- create type metatable
    local mtable = { MGL_type = k }
    for op, entry in pairs(op_metamethods) do -- bind metamethods
      mtable[entry[1]] = entry[2]
    end
    types[k] = mtable
    return mtable
  end
})

-- type metamethods update listener
listenOps(function(mgl, op)
  local entry = op_metamethods[op]
  if entry then
    -- re-generate metamethod
    entry[2] = gen_op_metamethod(op)

    -- update type metatables
    for mtype, mtable in pairs(types) do
      mtable[entry[1]] = entry[2]
    end
  end
end)

-- build tools module
local mglt = {
  genfunc = mglt_genfunc,
  genlist = mglt_genlist,
  tplsub = mglt_tplsub,
  format_proto = format_proto,
  format_call = format_call
}

-- build module
mgl = setmetatable({
  type = mgl_type,
  types = types,
  ops = ops,
  defOp = defOp,
  getOp = getOp,
  listenOps = listenOps,
  unlistenOps = unlistenOps,
  publishOps = publishOps,
  tools = mglt
}, {
  __index = function(self, k)
    -- generate operator
    local op = gen_op(k)
    self[k] = op
    return op
  end
})

-- bind/gen op metamethods
do
  local binds = {
    tostring = "__tostring",
    unm = "__unm",
    add = "__add",
    sub = "__sub",
    mul = "__mul",
    div = "__div",
    mod = "__mod",
    pow = "__pow",
    equal = "__eq",
    lessThan = "__lt",
    lessEqual = "__le"
  }
  for op, metamethod in pairs(binds) do
    op_metamethods[op] = {metamethod, gen_op_metamethod(op)}
  end
end

-- load modules

local modulepath = (...) and (...):gsub('%.mgl$', '') .. ".MGL." or ""


require(modulepath .. "scalar")(mgl, mglt)
require(modulepath .. "vector")(mgl, mglt)
require(modulepath .. "matrix")(mgl, mglt)
require(modulepath .. "transform")(mgl, mglt)

return mgl
