local luaunit = require('test.luaunit')

local mgl = require('src.mgl')

function testMGLTGenFunc()
	-- genfunc really just calls loadstring: it takes what you write, wraps it
	-- in function() ... end, returns the result.
	luaunit.assertEquals(mgl.tools.genfunc("return 4", "just 4")(), 4)
	-- but MGL wants this to actually error, so it converts the nil/message
	-- return from loadstring into an error.
	luaunit.assertErrorMsgContains("just 4", mgl.tools.genfunc, "MONKEYS 4", "just 4")
end

function testMGLTGenList()
	-- normal operation
	luaunit.assertEquals(mgl.tools.genlist("a$", 1, 4), "a1, a2, a3, a4")
	-- unusual indexes
	luaunit.assertEquals(mgl.tools.genlist("a$b", 3, 5, "; "), "a3b; a4b; a5b")
	-- no index target
	luaunit.assertEquals(mgl.tools.genlist("q", 1, 3), "q, q, q")
end

function testMGLTTplSub()
	-- replace instances of '$key' with value
	luaunit.assertEquals(mgl.tools.tplsub("$foo $bar", {foo = 'cheese', bar = 'monkeys'}), "cheese monkeys")
	-- don't touch just 'key'
	luaunit.assertEquals(mgl.tools.tplsub("$foo bar", {foo = 'cheese', bar = 'monkeys'}), "cheese bar")
end

function testMGLTFormatProto()
	-- a no-argument function should put nothing into the parentheses
	luaunit.assertEquals(mgl.tools.format_proto('foo'), 'foo()')
	-- a one-argument function should not have commas
	luaunit.assertEquals(mgl.tools.format_proto('foo', 'a'), 'foo(a)')
	-- a multiple-argument function should have commas and spaces between
	luaunit.assertEquals(mgl.tools.format_proto('foo', 'a', 'b', 'c'), 'foo(a, b, c)')
end

function testMGLTFormatCall()
	-- same basic deal as format_proto, but get the type of the things passed, instead of the values
	luaunit.assertEquals(mgl.tools.format_call('foo'), 'foo()')
	luaunit.assertEquals(mgl.tools.format_call('foo', 5), 'foo(number)')
	luaunit.assertEquals(mgl.tools.format_call('foo', setmetatable({},{MGL_type = "gerald"}), setmetatable({},{})), 'foo(gerald, table)')
end

function testMGLType()
	-- various built-in types should just say what they are.
	luaunit.assertEquals(mgl.type(nil), 'nil')
	luaunit.assertEquals(mgl.type(true), 'boolean')
	luaunit.assertEquals(mgl.type(0), 'number')
	luaunit.assertEquals(mgl.type('cake'), 'string')
	luaunit.assertEquals(mgl.type(math.sin), 'function')
	luaunit.assertEquals(mgl.type({}), 'table')
	-- a meta'd table without an mgl type should just count as a table.
	luaunit.assertEquals(mgl.type(setmetatable({},{})), 'table')
	-- but if MGL_type is a thing, read that
	luaunit.assertEquals(mgl.type(setmetatable({},{MGL_type = "gerald"})), 'gerald')
end

function testMGLListenOps()
	local a_result, b_result
	local function a(my_mgl, id)
		-- the first argument must always be mgl itself
		luaunit.assertEquals(my_mgl, mgl)
		a_result = id
	end
	local function b(my_mgl, id)
		luaunit.assertEquals(my_mgl, mgl)
		b_result = id
	end
	-- a is there, it gets called
	mgl.listenOps(a)
	mgl.publishOps('foo')
	luaunit.assertEquals(a_result, 'foo')
	luaunit.assertNil(b_result)
	-- now both are there, both should get called.
	a_result = nil
	mgl.listenOps(b)
	mgl.publishOps('bar')
	luaunit.assertEquals(a_result, 'bar')
	luaunit.assertEquals(b_result, 'bar')
	-- but now I took a out, so it shouldn't get called any more.
	a_result = nil
	b_result = nil
	mgl.unlistenOps(a)
	mgl.publishOps('baz')
	luaunit.assertNil(a_result)
	luaunit.assertEquals(b_result, 'baz')
end

-- defOp: given a function and a list of arg types,
-- 1. add the function to the argument dispatch table
-- 2. invalidate the flattened function
-- 3. publish that the function needs regenerating

-- getOp: given a function name and list of arg types,
-- find the pure function with that signature

-- these thus must run together in the unit tests; defOp a thing, getOp it
-- then proceed to check it's all there and gets called appropriately


function testMGLDefOp()
	local function n(a) return "n" end
	local function t(a) return "t" end
	local function any(a) return "*" end
	-- okay so.
	mgl.defOp(n, 'f', 'number')
	mgl.defOp(any, 'f', '*')
	luaunit.assertEquals(mgl.getOp('f', 'number'), n)
	luaunit.assertEquals(mgl.getOp('f', '*'), any)
	luaunit.assertEquals(mgl.f(5), "n")
	luaunit.assertEquals(mgl.f({}), "*")
	mgl.defOp(t, 'f', 'table')
	luaunit.assertEquals(mgl.getOp('f', 'table'), t)
	luaunit.assertEquals(mgl.f({}), "t")
	luaunit.assertEquals(mgl.f(true), "*")

	local function nn(a,b) return "nn" end
	local function at(a,b) return "*t" end

	mgl.defOp(nn, 'f', 'number', 'number')
	mgl.defOp(at, 'f', '*', 'table')
	-- I'm being intentionally picky here.
	-- the wildcard should pick up in this case:
	-- this clearly collects to "* table".
	luaunit.assertEquals(mgl.f(2,3), "nn")
	luaunit.assertEquals(mgl.f(2,{}), "*t")
	luaunit.assertErrorMsgContains("invalid", mgl.f, 1, 2, 3)
end

os.exit(luaunit.LuaUnit.run())