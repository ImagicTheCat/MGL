-- https://github.com/ImagicTheCat/MGL
-- MIT license (see LICENSE or MGL.lua)

local unpack = table.unpack or unpack

-- load
return function(mgl, mglt)
  local generated = {}

  -- Generate mat(N)(M)/mat(N) vector type.
  -- Matrix values are stored as a row-major ordered list; columns are vectors.
  -- N: columns
  -- M: (optional) rows (default: N)
  function mgl.gen_mat(N, M)
    M = M or N
    local vtype = "mat"..N..(M ~= N and "x"..M or "")
    if generated[vtype] then return end -- prevent regeneration
    local mt = mgl.types[vtype]
    mt.__index = {M = M, N = N}

    -- DATA
    -- gen: accessor vector
    do
      local g_as, s_as = {}, {}
      for i=1,M do -- retrieve column by index
        local a = "a["..((i-1)*N).."+idx]"
        table.insert(g_as, a)
        table.insert(s_as, a.." = b["..i.."]")
      end
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a, idx, b)
  if b then -- set vector
    $s_as
  else -- get vector
    return smt({$g_as}, mt)
  end
end
      ]], {
        g_as = table.concat(g_as, ", "),
        s_as = table.concat(s_as, "\n")
      })
      local f = mglt.genfunc(code, vtype..":accessor_vector")(mgl.types["vec"..M])
      mt.__index.v = f
    end

    -- gen: copy
    do
      local code = mglt.tplsub([[
return function(a,b)
  $ops
end
      ]], {ops = mglt.genlist("a[$] = b[$]", 1, M*N, "\n")})
      local f = mglt.genfunc(code, vtype..":copy")()
      mgl.defOp(f, "copy", vtype, vtype)
    end

    -- CONSTRUCTORS
    -- gen: constructor scalar
    do
      -- generate identity
      local vs = {}; for i=1,N*M do table.insert(vs, (i-1)%N == math.floor((i-1)/N) and "x" or "0") end
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(x) return smt({$vs}, mt) end
      ]], {vs = table.concat(vs, ",")})
      local f = mglt.genfunc(code, vtype..":constructor_scalar")(mt)
      mgl.defOp(f, vtype, "number")
    end

    -- gen: constructor list
    do
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(t) return smt({$ts}, mt) end
      ]], {ts = mglt.genlist("t[$]", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":constructor_list")(mt)
      mgl.defOp(f, vtype, "table")
    end

    -- gen: constructor copy
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a) return smt({$as}, gmt(a)) end
      ]], {as = mglt.genlist("a[$]", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":constructor_copy")()
      mgl.defOp(f, vtype, vtype)
    end

    -- gen: constructor extend square
    if M == N then
      local as = {}
      for i=1,M-1 do
        for j=1,M-1 do table.insert(as, "a["..(j+(i-1)*(M-1)).."]") end
        table.insert(as, "0")
      end
      for i=1,M-1 do table.insert(as, "0") end; table.insert(as, "1")

      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a) return smt({$as}, mt) end
      ]], {as = table.concat(as, ", ")})
      local f = mglt.genfunc(code, vtype..":constructor_extend_square")(mt)
      mgl.defOp(f, vtype, "mat"..(M-1))
    end

    -- gen: constructor truncate square
    if M == N then
      local as = {}
      for i=1,M do
        for j=1,M do table.insert(as, "a["..(j+(i-1)*(M+1)).."]") end
      end

      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a) return smt({$as}, mt) end
      ]], {as = table.concat(as, ", ")})
      local f = mglt.genfunc(code, vtype..":constructor_truncate_square")(mt)
      mgl.defOp(f, vtype, "mat"..(M+1))
    end

    -- gen: constructor vectors (columns)
    do
      local ptypes = {}
      local vcs = {}
      for i=1,N do
        table.insert(ptypes, "vec"..M)
        -- write vector components to row-major order
        for j=1,M do table.insert(vcs, "v"..j.."["..i.."]") end
      end
      local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function($vs) return smt({$vcs}, mt) end
      ]], {
        vs = mglt.genlist("v$", 1, N),
        vcs = table.concat(vcs, ", ")
      })
      local f = mglt.genfunc(code, vtype..":constructor_vectors")(mt)
      mgl.defOp(f, vtype, unpack(ptypes))
    end

    -- MISC
    -- gen: tostring
    do
      local lines = {}
      for i=1,M do
        local line = mglt.tplsub([[tins(t, "|"..$cs.."|")]], --
          {cs = mglt.genlist("a[$]", (i-1)*N+1, i*N, [[..","..]])})
        table.insert(lines, line)
      end
      local code = mglt.tplsub([[
local tins, tcc = table.insert, table.concat
return function(a)
  local t = {}
  $inserts
  return tcc(t, "\n")
end
      ]], {inserts = table.concat(lines, "\n")})
      local f = mglt.genfunc(code, vtype..":tostring")()
      mgl.defOp(f, "tostring", vtype)
    end

    -- COMPARISON
    -- gen: equal
    do
      local code = mglt.tplsub([[return function(a, b) return $expr end]], --
        {expr = mglt.genlist("a[$] == b[$]", 1, M*N, " and ")})
      local f = mglt.genfunc(code, vtype..":equal")()
      mgl.defOp(f, "equal", vtype, vtype)
    end

    -- BASIC ARITHMETIC
    -- gen: unm
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("-a[$]", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":unm")()
      mgl.defOp(f, "unm", vtype)
    end

    -- gen: add
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]+b[$]", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":add")()
      mgl.defOp(f, "add", vtype, vtype)
    end

    -- gen: sub
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]-b[$]", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":sub")()
      mgl.defOp(f, "sub", vtype, vtype)
    end

    -- gen: mul number
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, n) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*n", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":mul_number")()
      mgl.defOp(f, "mul", vtype, "number")
    end

    -- gen: mul number alt
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(n, a) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]*n", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":mul_number_alt")()
      mgl.defOp(f, "mul", "number", vtype)
    end

    -- gen: div number
    do
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, n) return smt({$opl}, gmt(a)) end
      ]], {opl = mglt.genlist("a[$]/n", 1, M*N)})
      local f = mglt.genfunc(code, vtype..":div_number")()
      mgl.defOp(f, "div", vtype, "number")
    end

    -- gen: mul square
    if M == N then
      local opl = {}
      for i=1,M do -- each row of a
        for j=1,N do -- each column of b
          local adds = {}
          for n=1,N do
            table.insert(adds, "a["..(n+(i-1)*N).."]*b["..(j+(n-1)*N).."]")
          end
          table.insert(opl, table.concat(adds, "+"))
        end
      end
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(a)) end
      ]], {opl = table.concat(opl, ", ")})
      local f = mglt.genfunc(code, vtype..":mul_square")()
      mgl.defOp(f, "mul", vtype, vtype)
    end

    -- gen: mul square vec
    if M == N then
      local opl = {}
      for i=1,M do -- each row of a
        local adds = {}
        for n=1,N do
          table.insert(adds, "a["..(n+(i-1)*N).."]*b["..n.."]")
        end
        table.insert(opl, table.concat(adds, "+"))
      end
      local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a, b) return smt({$opl}, gmt(b)) end
      ]], {opl = table.concat(opl, ", ")})
      local f = mglt.genfunc(code, vtype..":mul_square_vec")()
      mgl.defOp(f, "mul", vtype, "vec"..N)
    end

    -- gen: mul general (mat/vec)
    do
      local mgl_type, format_call, smt, match = mgl.type, mglt.format_call, setmetatable, string.match
      local tonumber, types = tonumber, mgl.types
      local function f(a,b)
        -- check b type
        local Mb, Nb
        local btype = mgl_type(b)
        if match(btype, "^mat%d+.*$") then Mb, Nb = b.M, b.N -- mat
        elseif match(btype, "^vec%d+$") then Mb, Nb = #b, 1 end -- vec
        if N ~= Mb then error("invalid operator prototype "..format_call("mul", a, b)) end
        -- compute result matrix
        --- result type
        local rtype = (Nb == 1 and "vec"..M or (M == Nb and "mat"..M or "mat"..Nb.."x"..M))
        --- values
        local r = {}
        for i=1,M do -- each row of a
          for j=1,Nb do -- each column of b
            local sum = 0
            for n=1,N do sum = sum + a[n+(i-1)*N]*b[j+(n-1)*Nb] end
            r[j+(i-1)*Nb] = sum
          end
        end
        return smt(r, types[rtype])
      end
      mgl.defOp(f, "mul", vtype, "*")
    end

    -- OPERATIONS
    -- gen: transpose
    do
      local as = {}
      for i=1,N do for j=1,M do table.insert(as, "a["..((j-1)*N+i).."]") end end

      if M == N then -- square
        local code = mglt.tplsub([[
local gmt, smt = getmetatable, setmetatable
return function(a) return smt({$as}, gmt(a)) end
        ]], {as = table.concat(as, ", ")})
        local f = mglt.genfunc(code, vtype..":transpose")()
        mgl.defOp(f, "transpose", vtype)
      else -- general case
        local code = mglt.tplsub([[
local mt = ...
local smt = setmetatable
return function(a) return smt({$as}, mt) end
        ]], {as = table.concat(as, ", ")})
        local f = mglt.genfunc(code, vtype..":transpose")(mgl.types["mat"..M.."x"..N])
        mgl.defOp(f, "transpose", vtype)
      end
    end

    -- Determinant and inverse based on:
    --- https://en.wikipedia.org/wiki/Invertible_matrix
    --- https://github.com/willnode/N-Matrix-Programmer

    -- gen: determinant / inverse
    if M == N and M == 2 then -- mat2
      -- determinant
      local function f(a)
        return a[1]*a[4]-a[2]*a[3]
      end
      mgl.defOp(f, "determinant", vtype)

      -- inverse
      local gmt, smt = getmetatable, setmetatable
      local function f(a)
        local d = a[1]*a[4]-a[2]*a[3]
        local invd = 1/d
        if d ~= 0 then
          return smt({a[4]*invd, -a[2]*invd, -a[3]*invd, a[1]*invd}, gmt(a)), d
        else
          local nan = 0/0
          return smt({nan,nan,nan,nan}, gmt(a)), d
        end
      end
      mgl.defOp(f, "inverse", vtype)
    elseif M == N and M == 3 then -- mat3
      -- determinant
      local function f(a)
        return a[1]*(a[5]*a[9]-a[6]*a[8]) --
          -a[2]*(a[4]*a[9]-a[6]*a[7]) --
          +a[3]*(a[4]*a[8]-a[5]*a[7])
      end
      mgl.defOp(f, "determinant", vtype)

      -- inverse
      local gmt, smt = getmetatable, setmetatable
      local function f(a)
        local d = a[1]*(a[5]*a[9]-a[6]*a[8]) --
          -a[2]*(a[4]*a[9]-a[6]*a[7]) --
          +a[3]*(a[4]*a[8]-a[5]*a[7])
        local invd = 1/d
        if d ~= 0 then
          return smt({
            invd*(a[5]*a[9] - a[6]*a[8]),
            invd*-(a[2]*a[9] - a[3]*a[8]),
            invd*(a[2]*a[6] - a[3]*a[5]),
            invd*-(a[4]*a[9] - a[6]*a[7]),
            invd*(a[1]*a[9] - a[3]*a[7]),
            invd*-(a[1]*a[6] - a[3]*a[4]),
            invd*(a[4]*a[8] - a[5]*a[7]),
            invd*-(a[1]*a[8] - a[2]*a[7]),
            invd*(a[1]*a[5] - a[2]*a[4])
          }, gmt(a)), d
        else
          local nan = 0/0
          return smt({nan,nan,nan,nan,nan,nan,nan,nan,nan}, gmt(a)), d
        end
      end
      mgl.defOp(f, "inverse", vtype)
    elseif M == N and M == 4 then -- mat4
      -- determinant
      local function f(a)
        local A2323 = a[11]*a[16] - a[12]*a[15]
        local A1323 = a[10]*a[16] - a[12]*a[14]
        local A1223 = a[10]*a[15] - a[11]*a[14]
        local A0323 = a[9]*a[16] - a[12]*a[13]
        local A0223 = a[9]*a[15] - a[11]*a[13]
        local A0123 = a[9]*a[14] - a[10]*a[13]
        local A2313 = a[7]*a[16] - a[8]*a[15]
        local A1313 = a[6]*a[16] - a[8]*a[14]
        local A1213 = a[6]*a[15] - a[7]*a[14]
        local A2312 = a[7]*a[12] - a[8]*a[11]
        local A1312 = a[6]*a[12] - a[8]*a[10]
        local A1212 = a[6]*a[11] - a[7]*a[10]
        local A0313 = a[5]*a[16] - a[8]*a[13]
        local A0213 = a[5]*a[15] - a[7]*a[13]
        local A0312 = a[5]*a[12] - a[8]*a[9]
        local A0212 = a[5]*a[11] - a[7]*a[9]
        local A0113 = a[5]*a[14] - a[6]*a[13]
        local A0112 = a[5]*a[10] - a[6]*a[9]

        return a[1]*(a[6]*A2323 - a[7]*A1323 + a[8]*A1223)
          - a[2]*(a[5]*A2323 - a[7]*A0323 + a[8]*A0223)
          + a[3]*(a[5]*A1323 - a[6]*A0323 + a[8]*A0123)
          - a[4]*(a[5]*A1223 - a[6]*A0223 + a[7]*A0123)
      end
      mgl.defOp(f, "determinant", vtype)

      -- inverse
      local gmt, smt = getmetatable, setmetatable
      local function f(a)
        local A2323 = a[11]*a[16] - a[12]*a[15]
        local A1323 = a[10]*a[16] - a[12]*a[14]
        local A1223 = a[10]*a[15] - a[11]*a[14]
        local A0323 = a[9]*a[16] - a[12]*a[13]
        local A0223 = a[9]*a[15] - a[11]*a[13]
        local A0123 = a[9]*a[14] - a[10]*a[13]
        local A2313 = a[7]*a[16] - a[8]*a[15]
        local A1313 = a[6]*a[16] - a[8]*a[14]
        local A1213 = a[6]*a[15] - a[7]*a[14]
        local A2312 = a[7]*a[12] - a[8]*a[11]
        local A1312 = a[6]*a[12] - a[8]*a[10]
        local A1212 = a[6]*a[11] - a[7]*a[10]
        local A0313 = a[5]*a[16] - a[8]*a[13]
        local A0213 = a[5]*a[15] - a[7]*a[13]
        local A0312 = a[5]*a[12] - a[8]*a[9]
        local A0212 = a[5]*a[11] - a[7]*a[9]
        local A0113 = a[5]*a[14] - a[6]*a[13]
        local A0112 = a[5]*a[10] - a[6]*a[9]

        local d = a[1]*(a[6]*A2323 - a[7]*A1323 + a[8]*A1223)
          - a[2]*(a[5]*A2323 - a[7]*A0323 + a[8]*A0223)
          + a[3]*(a[5]*A1323 - a[6]*A0323 + a[8]*A0123)
          - a[4]*(a[5]*A1223 - a[6]*A0223 + a[7]*A0123)
        local invd = 1/d
        if d ~= 0 then
          return smt({
            invd*(a[6]*A2323 - a[7]*A1323 + a[8]*A1223),
            invd* -(a[2]*A2323 - a[3]*A1323 + a[4]*A1223),
            invd*(a[2]*A2313 - a[3]*A1313 + a[4]*A1213),
            invd* -(a[2]*A2312 - a[3]*A1312 + a[4]*A1212),
            invd* -(a[5]*A2323 - a[7]*A0323 + a[8]*A0223),
            invd*(a[1]*A2323 - a[3]*A0323 + a[4]*A0223),
            invd* -(a[1]*A2313 - a[3]*A0313 + a[4]*A0213),
            invd*(a[1]*A2312 - a[3]*A0312 + a[4]*A0212),
            invd*(a[5]*A1323 - a[6]*A0323 + a[8]*A0123),
            invd* -(a[1]*A1323 - a[2]*A0323 + a[4]*A0123),
            invd*(a[1]*A1313 - a[2]*A0313 + a[4]*A0113),
            invd* -(a[1]*A1312 - a[2]*A0312 + a[4]*A0112),
            invd* -(a[5]*A1223 - a[6]*A0223 + a[7]*A0123),
            invd*(a[1]*A1223 - a[2]*A0223 + a[3]*A0123),
            invd* -(a[1]*A1213 - a[2]*A0213 + a[3]*A0113),
            invd*(a[1]*A1212 - a[2]*A0212 + a[3]*A0112)
          }, gmt(a)), d
        else
          local nan = 0/0
          return smt({nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan,nan}, gmt(a)), d
        end
      end
      mgl.defOp(f, "inverse", vtype)
    end

    generated[vtype] = true
  end
end
