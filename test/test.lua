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
	luaunit.assertEquals(mgl.tools.tplsub("$foo $bar", {foo = 'cheese', bar = 'monkeys'}), "cheese monkeys")
	luaunit.assertEquals(mgl.tools.tplsub("$foo bar", {foo = 'cheese', bar = 'monkeys'}), "cheese bar")
	-- I don't know what all else to test here; tplsub does no error checking
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


os.exit(luaunit.LuaUnit.run())