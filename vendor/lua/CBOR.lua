--
-- lua-ConciseSerialization : <http://fperrad.github.io/lua-ConciseSerialization/>
--

local assert = assert
local error = error
local pairs = pairs
local pcall = pcall
local setmetatable = setmetatable
local tostring = tostring
local type = type
local char = require'string'.char
local format = require'string'.format
local math_type = require'math'.type
local frexp = require'math'.frexp or require'mathx'.frexp
local ldexp = require'math'.ldexp or require'mathx'.ldexp
local huge = require'math'.huge
local tconcat = require'table'.concat
local pack = require'string'.pack
local unpack = require'string'.unpack
local utf8_len = require'utf8'.len

local _ENV = nil
local m = {}

--[[ debug only
local function hexadump (s)
    return (s:gsub('.', function (c) return format('%02X ', c:byte()) end))
end
m.hexadump = hexadump
--]]

local function argerror (caller, narg, extramsg)
    error("bad argument #" .. tostring(narg) .. " to "
          .. caller .. " (" .. extramsg .. ")")
end

local function typeerror (caller, narg, arg, tname)
    argerror(caller, narg, tname .. " expected, got " .. type(arg))
end

local function checktype (caller, narg, arg, tname)
    if type(arg) ~= tname then
        typeerror(caller, narg, arg, tname)
    end
end

local function checkunsigned (caller, narg, arg)
    if math_type(arg) ~= 'integer' or arg < 0 then
        typeerror(caller, narg, arg, 'positive integer')
    end
end

local function pack_half_float(n)
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = frexp(n)
    if mant ~= mant then
        return char(0x7E, 0x00)         -- nan
    elseif mant == huge or expo > 0x10 then
        if sign == 0 then
            return char(0x7C, 0x00)     -- inf
        else
            return char(0xFC, 0x00)     -- -inf
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x0E then
        return char(sign, 0x00)         -- zero
    else
        expo = expo + 0x0E
        mant = (mant * 2.0 - 1.0) * ldexp(0.5, 11) // 1
        return char(sign + expo * 0x04 + mant // 0x100,
                    mant % 0x100)
    end
end

local coders = setmetatable({}, {
    __index = function (t, k) error("encode '" .. k .. "' is unimplemented") end
})
m.coders = coders

local function encode_unsigned (n, major)
    if n <= 0x17 then
        return char(major + n)
    elseif n <= 0xFF then
        return char(major + 0x18, n)
    elseif n <= 0xFFFF then
        return pack('>BI2', major + 0x19, n)
    elseif n <= 4294967295.0 then
        return pack('>BI4', major + 0x1A, n)
    else
        return pack('>BI8', major + 0x1B, n)
    end
end

coders['integer'] = function (buffer, n)
    if n >= 0 then
        buffer[#buffer+1] = encode_unsigned(n, 0x00)
    else
        buffer[#buffer+1] = encode_unsigned(-1 - n, 0x20)
    end
end

m.OPEN_BYTE_STRING = char(0x5F)

m.BYTE_STRING = function (n)
    checkunsigned('BYTE_STRING', 1, n)
    return encode_unsigned(n, 0x40)
end

coders['byte_string'] = function (buffer, str)
    buffer[#buffer+1] = encode_unsigned(#str, 0x40)
    buffer[#buffer+1] = str
end

m.OPEN_TEXT_STRING = char(0x7F)

m.TEXT_STRING = function (n)
    checkunsigned('TEXT_STRING', 1, n)
    return encode_unsigned(n, 0x60)
end

coders['text_string'] = function (buffer, str)
    buffer[#buffer+1] = encode_unsigned(#str, 0x60)
    buffer[#buffer+1] = str
end

local function set_string (option)
    if option == 'byte_string' then
        coders['string'] = coders['byte_string']
    elseif option == 'text_string' then
        coders['string'] = coders['text_string']
    elseif option == 'check_utf8' then
        coders['string'] = function (buffer, str)
            if utf8_len(str) then
                coders['text_string'](buffer, str)
            else
                coders['byte_string'](buffer, str)
            end
        end
    else
        argerror('set_string', 1, "invalid option '" .. option .."'")
    end
end
m.set_string = set_string

m.OPEN_ARRAY = char(0x9F)

m.ARRAY = function (n)
    checkunsigned('ARRAY', 1, n)
    return encode_unsigned(n, 0x80)
end

coders['array'] = function (buffer, tbl, n)
    buffer[#buffer+1] = encode_unsigned(n, 0x80)
    for i = 1, n do
        local v = tbl[i]
        coders[type(v)](buffer, v)
    end
end

m.OPEN_MAP = char(0xBF)

m.MAP = function (n)
    checkunsigned('MAP', 1, n)
    return encode_unsigned(n, 0xA0)
end

coders['map'] = function (buffer, tbl, n)
    buffer[#buffer+1] = encode_unsigned(n, 0xA0)
    for k, v in pairs(tbl) do
        coders[type(k)](buffer, k)
        coders[type(v)](buffer, v)
    end
end

local function set_array (option)
    if option == 'without_hole' then
        coders['_table'] = function (buffer, tbl)
            local is_map, n, max = false, 0, 0
            for k in pairs(tbl) do
                if type(k) == 'number' and k > 0 then
                    if k > max then
                        max = k
                    end
                else
                    is_map = true
                end
                n = n + 1
            end
            if max ~= n then    -- there are holes
                is_map = true
            end
            if is_map then
                coders['map'](buffer, tbl, n)
            else
                coders['array'](buffer, tbl, n)
            end
        end
    elseif option == 'with_hole' then
        coders['_table'] = function (buffer, tbl)
            local is_map, n, max = false, 0, 0
            for k in pairs(tbl) do
                if type(k) == 'number' and k > 0 then
                    if k > max then
                        max = k
                    end
                else
                    is_map = true
                end
                n = n + 1
            end
            if is_map then
                coders['map'](buffer, tbl, n)
            else
                coders['array'](buffer, tbl, max)
            end
        end
    elseif option == 'always_as_map' then
        coders['_table'] = function(buffer, tbl)
            local n = 0
            for _ in pairs(tbl) do
                n = n + 1
            end
            coders['map'](buffer, tbl, n)
        end
    else
        argerror('set_array', 1, "invalid option '" .. option .."'")
    end
end
m.set_array = set_array

coders['table'] = function (buffer, tbl)
    coders['_table'](buffer, tbl)
end

local function TAG (n)
    checkunsigned('TAG', 1, n)
    return encode_unsigned(n, 0xC0)
end
m.TAG = TAG

coders['tag'] = function (buffer, n)
    buffer[#buffer+1] = TAG(n)
end

m.BREAK = char(0xFF)

local function SIMPLE (n)
    checkunsigned('SIMPLE', 1, n)
    if n >= 0x100 then
        argerror('SIMPLE', 1, "out of range")
    end
    if n <= 0x17 then
        return char(0xE0 + n)
    else
        return char(0xF8, n)
    end
end
m.SIMPLE = SIMPLE

coders['simple'] = function (buffer, n)
    buffer[#buffer+1] = SIMPLE(n)
end

coders['boolean'] = function (buffer, bool)
    if bool then
        buffer[#buffer+1] = char(0xF5)          -- true
    else
        buffer[#buffer+1] = char(0xF4)          -- false
    end
end

coders['null'] = function (buffer)
    buffer[#buffer+1] = char(0xF6)              -- null
end

coders['undef'] = function (buffer)
    buffer[#buffer+1] = char(0xF7)              -- undef
end

local function set_nil (option)
    if option == 'null' then
        coders['nil'] = coders['null']
    elseif option == 'undef' then
        coders['nil'] = coders['undef']
    else
        argerror('set_nil', 1, "invalid option '" .. option .."'")
    end
end
m.set_nil = set_nil

coders['half'] = function (buffer, n)
    buffer[#buffer+1] = char(0xF9)
    buffer[#buffer+1] = pack_half_float(n)
end

coders['single'] = function (buffer, n)
    buffer[#buffer+1] = pack('>Bf', 0xFA, n)
end

coders['double'] = function (buffer, n)
    buffer[#buffer+1] = pack('>Bd', 0xFB, n)
end

local function set_float (option)
    if option == 'half' then
        coders['float'] = coders['half']
    elseif option == 'single' then
        coders['float'] = coders['single']
    elseif option == 'double' then
        coders['float'] = coders['double']
    else
        argerror('set_float', 1, "invalid option '" .. option .."'")
    end
end
m.set_float = set_float

coders['number'] = function (buffer, n)
    coders[math_type(n)](buffer, n)
end

function m.encode (data)
    local buffer = {}
    coders[type(data)](buffer, data)
    return tconcat(buffer)
end

m.MAGIC = char(0xD9, 0xD9, 0xF7)        -- tag 55799

local decoders  -- forward declaration

local function lookahead (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    return s:sub(i, i):byte()
end

local function decode_cursor (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    local val = s:sub(i, i):byte()
    c.i = i+1
    return decoders[val](c, val)
end
m.decode_cursor = decode_cursor

local function decode_uint8 (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+1
    return unpack('>I1', s, i)
end

local function decode_uint16 (c)
    local s, i, j = c.s, c.i, c.j
    if i+1 > j then
        c:underflow(i+1)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+2
    return unpack('>I2', s, i)
end

local function decode_uint32 (c)
    local s, i, j = c.s, c.i, c.j
    if i+3 > j then
        c:underflow(i+3)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+4
    return unpack('>I4', s, i)
end

local function decode_uint64 (c)
    local s, i, j = c.s, c.i, c.j
    if i+7 > j then
        c:underflow(i+7)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+8
    return unpack('>I8', s, i)
end

local function decode_string (c, n)
    local s, i, j = c.s, c.i, c.j
    local e = i+n-1
    if e > j or n < 0 then
        c:underflow(e)
        s, i, j = c.s, c.i, c.j
        e = i+n-1
    end
    c.i = i+n
    return s:sub(i, e)
end

local function decode_stringx (c, major)
    local t = {}
    while true do
        local ahead = lookahead(c)
        if ahead == 0xFF then
            c.i = c.i+1
            break
        end
        assert(ahead >= major and ahead <= major + 0x1B, "bad major inside indefinite-length string")
        t[#t+1] = decode_cursor(c)
    end
    return tconcat(t)
end

local function check_utf8 (s)
    if m.strict and not utf8_len(s) then
        error("invalid UTF-8 string")
    end
    return s
end

local function decode_array (c, n)
    local t = {}
    for i = 1, n do
        t[i] = decode_cursor(c)
    end
    return t
end

local function decode_arrayx (c)
    local t = {}
    while true do
        if lookahead(c) == 0xFF then
            c.i = c.i+1
            break
        end
        t[#t+1] = decode_cursor(c)
    end
    return t
end

local function decode_map (c, n)
    local t = {}
    for _ = 1, n do
        local k = decode_cursor(c)
        local val = decode_cursor(c)
        if k == nil or k ~= k then
            k = m.sentinel
        end
        if m.strict and t[k] ~= nil then
            error("duplicated keys")
        end
        if k ~= nil then
            t[k] = val
        end
    end
    return t
end

local function decode_mapx (c)
    local t = {}
    while true do
        if lookahead(c) == 0xFF then
            c.i = c.i+1
            break
        end
        local k = decode_cursor(c)
        local val = decode_cursor(c)
        if k == nil or k ~= k then
            k = m.sentinel
        end
        if m.strict and t[k] ~= nil then
            error("duplicated keys")
        end
        if k ~= nil then
            t[k] = val
        end
    end
    return t
end

local builders = {}

function m.register_tag(tag, builder)
    checkunsigned('register_tag', 1, tag)
    checktype('register_tag', 2, builder, 'function')
    builders[tag] = builder
end

local function decode_tag (c, tag)
    if tag == 24 then   -- encoded CBOR data item
        local sav = m.strict
        m.strict = false
        local i = c.i
        decode_cursor(c)
        m.strict = sav
        return c.s:sub(i, c.i)
    else
        local val = decode_cursor(c)
        local builder = builders[tag]
        return builder and builder(val) or val
    end
end

local values = {}

function m.register_simple(n, val)
    checkunsigned('register_simple', 1, n)
    values[n] = val
end

local function decode_simple(n)
    return values[n] or n
end

local function decode_half_float (c)
    local s, i, j = c.s, c.i, c.j
    if i+1 > j then
        c:underflow(i+1)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2 = s:sub(i, i+1):byte(1, 2)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) // 0x04
    local mant = (b1 % 0x04) * 0x100 + b2
    if sign then
        sign = -1
    else
        sign = 1
    end
    local n
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0x1F then
        if mant == 0 then
            n = sign * huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * ldexp(1.0 + mant / 0x400, expo - 0x0F)
    end
    c.i = i+2
    return n
end

local function decode_single_float (c)
    local s, i, j = c.s, c.i, c.j
    if i+3 > j then
        c:underflow(i+3)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+4
    return unpack('>f', s, i)
end

local function decode_double_float (c)
    local s, i, j = c.s, c.i, c.j
    if i+7 > j then
        c:underflow(i+7)
        s, i, j = c.s, c.i, c.j
    end
    c.i = i+8
    return unpack('>d', s, i)
end

local direct_small = {
    [0x00] = function (c, val) return val end,
    [0x20] = function (c, val) return 0x1F - val end,
    [0x40] = function (c, val) return decode_string(c, val - 0x40) end,
    [0x60] = function (c, val) return check_utf8(decode_string(c, val - 0x60)) end,
    [0x80] = function (c, val) return decode_array(c, val - 0x80) end,
    [0xA0] = function (c, val) return decode_map(c, val - 0xA0) end,
    [0xC0] = decode_tag,
    [0xE0] = function (c, val) return decode_simple(val - 0xE0) end,
}
decoders = {
    -- 0x00..0x17   unsigned integer
    [0x18] = decode_uint8,
    [0x19] = decode_uint16,
    [0x1A] = decode_uint32,
    [0x1B] = decode_uint64,
    -- 0x20..0x37   negative integer
    [0x38] = function (c) return -1 - decode_uint8(c) end,
    [0x39] = function (c) return -1 - decode_uint16(c) end,
    [0x3A] = function (c) return -1 - decode_uint32(c) end,
    [0x3B] = function (c) return -1 - decode_uint64(c) end,
    -- 0x40..0x57   byte string
    [0x58] = function (c) return decode_string(c, decode_uint8(c)) end,
    [0x59] = function (c) return decode_string(c, decode_uint16(c)) end,
    [0x5A] = function (c) return decode_string(c, decode_uint32(c)) end,
    [0x5B] = function (c) return decode_string(c, decode_uint64(c)) end,
    [0x5F] = function (c) return decode_stringx(c, 0x40) end,
    -- 0x60..0x77   text string
    [0x78] = function (c) return check_utf8(decode_string(c, decode_uint8(c))) end,
    [0x79] = function (c) return check_utf8(decode_string(c, decode_uint16(c))) end,
    [0x7A] = function (c) return check_utf8(decode_string(c, decode_uint32(c))) end,
    [0x7B] = function (c) return check_utf8(decode_string(c, decode_uint64(c))) end,
    [0x7F] = function (c) return check_utf8(decode_stringx(c, 0x60)) end,
    -- 0x80..0x97   array
    [0x98] = function (c) return decode_array(c, decode_uint8(c)) end,
    [0x99] = function (c) return decode_array(c, decode_uint16(c)) end,
    [0x9A] = function (c) return decode_array(c, decode_uint32(c)) end,
    [0x9B] = function (c) return decode_array(c, decode_uint64(c)) end,
    [0x9F] = decode_arrayx,
    -- 0xA0..0xB7   map
    [0xB8] = function (c) return decode_map(c, decode_uint8(c)) end,
    [0xB9] = function (c) return decode_map(c, decode_uint16(c)) end,
    [0xBA] = function (c) return decode_map(c, decode_uint32(c)) end,
    [0xBB] = function (c) return decode_map(c, decode_uint64(c)) end,
    [0xBF] = decode_mapx,
    -- 0xC0..0xD7   tag
    [0xD8] = function (c) return decode_tag(c, decode_uint8(c)) end,
    [0xD9] = function (c) return decode_tag(c, decode_uint16(c)) end,
    [0xDA] = function (c) return decode_tag(c, decode_uint32(c)) end,
    [0xDB] = function (c) return decode_tag(c, decode_uint64(c)) end,
    -- 0xE0..0xF3   value
    [0xF4] = function () return false end,
    [0xF5] = function () return true end,
    [0xF6] = function () return nil end,
    [0xF7] = function () return nil end,
    [0xF8] = function (c, val) return decode_simple(decode_uint8(c)) end,
    [0xF9] = decode_half_float,
    [0xFA] = decode_single_float,
    [0xFB] = decode_double_float,
    [0xFF] = function () error("unexpected BREAK") end,
}
for k, v in pairs(direct_small) do
    for i = 0, 0x17 do
        if not decoders[k+i] then
            decoders[k+i] = v
        end
    end
end
setmetatable(decoders, {
    __index = function (t, k) error("decode '" .. format('0x%X', k) .. "' is unimplemented") end
})

local function cursor_string (str)
    return {
        s = str,
        i = 1,
        j = #str,
        underflow = function ()
                        error "missing bytes"
                    end,
    }
end

local function cursor_loader (ld)
    return {
        s = '',
        i = 1,
        j = 0,
        underflow = function (self, e)
                        self.s = self.s:sub(self.i)
                        e = e - self.i + 1
                        self.i = 1
                        self.j = 0
                        while e > self.j do
                            local chunk = ld()
                            if not chunk then
                                error "missing bytes"
                            end
                            self.s = self.s .. chunk
                            self.j = #self.s
                        end
                    end,
    }
end

function m.decode (s)
    checktype('decode', 1, s, 'string')
    local cursor = cursor_string(s)
    local data = decode_cursor(cursor)
    if cursor.i < cursor.j then
        error "extra bytes"
    end
    return data
end

function m.decoder (src)
    if type(src) == 'string' then
        local cursor = cursor_string(src)
        return function ()
            if cursor.i <= cursor.j then
                return cursor.i, decode_cursor(cursor)
            end
        end
    elseif type(src) == 'function' then
        local cursor = cursor_loader(src)
        return function ()
            if cursor.i > cursor.j then
                pcall(cursor.underflow, cursor, cursor.i)
            end
            if cursor.i <= cursor.j then
                return true, decode_cursor(cursor)
            end
        end
    else
        argerror('decoder', 1, "string or function expected, got " .. type(src))
    end
end

set_nil'undef'
set_string'text_string'
set_array'without_hole'
m.strict = true
if #pack('n', 0.0) == 4 then
    m.small_lua = true
    for i = 0x1B, 0xFB, 0x20 do
        decoders[i] = nil       -- 64 bits
    end
    set_float'single'
else
    m.full64bits = true
    set_float'double'
    if #pack('n', 0.0) > 8 then
        m.long_double = true
    end
end

m._VERSION = '0.2.0'
m._DESCRIPTION = "lua-ConciseSerialization : a pure Lua 5.3 implementation of CBOR / RFC7049"
m._COPYRIGHT = "Copyright (c) 2016-2017 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
