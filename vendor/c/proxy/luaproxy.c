/*
 * Copyright (c) 2011 - 2017, Micro Systems Marc Balmer, CH-5073 Gipf-Oberfrick
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Micro Systems Marc Balmer nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* State proxy for Lua */

#include <sys/types.h>

#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "luaproxy.h"

static int proxy_dostring(lua_State *);
static void proxy_unmap(lua_State *L, lua_State *R);

static int
proxy_clear(lua_State *L)
{
	proxy_data *p = luaL_checkudata(L, 1, PROXY_METATABLE);
	if (p->close_on_gc)
		lua_close(p->L);
	return 0;
}

static int
object_clear(lua_State *L)
{
	proxy_object *o = luaL_checkudata(L, 1, OBJECT_METATABLE);

	luaL_unref(o->L, LUA_REGISTRYINDEX, o->ref);
	return 0;
}

static int
proxy_index(lua_State *L)
{
	proxy_data *p;
	char nam[64];

	p = luaL_checkudata(L, -2, PROXY_METATABLE);
	luaL_argcheck(L, p->L != NULL, -2, "no State data set");

	if (lua_type(L, -1) == LUA_TNUMBER)
		snprintf(nam, sizeof nam, "%d", (int)lua_tonumber(L, -1));
	else
		snprintf(nam, sizeof nam, "%s", lua_tostring(L, -1));

	if (!strcmp(nam, "dostring"))
		lua_pushcfunction(L, proxy_dostring);
	else {
		lua_getglobal(p->L, nam);
		proxy_unmap(L, p->L);
	}
	return 1;
}

static void
proxy_map(lua_State *L, lua_State *R, int t, int global)
{
	int top;
	char nam[64];

	luaL_checkstack(R, 3, "out of stack space");
	switch (lua_type(L, -2)) {
	case LUA_TNUMBER:
		lua_pushnumber(R, lua_tonumber(L, -2));
		snprintf(nam, sizeof nam, "%d", (int)lua_tonumber(L, -2));
		break;
	case LUA_TSTRING:
		snprintf(nam, sizeof nam, "%s", lua_tostring(L, -2));
		lua_pushstring(R, lua_tostring(L, -2));
		break;
	default:
		luaL_error(L, "proxy: data type '%s' is not "
		    "supported as an index value", luaL_typename(L, -2));
		return;
	}
	switch (lua_type(L, -1)) {
	case LUA_TBOOLEAN:
		lua_pushboolean(R, lua_toboolean(L, -1));
		break;
	case LUA_TNUMBER:
#if LUA_VERSION_NUM >= 503
		if (lua_isinteger(L, -1))
			lua_pushinteger(R, lua_tointeger(L, -1));
		else
#endif
			lua_pushnumber(R, lua_tonumber(L, -1));
		break;
	case LUA_TSTRING:
		lua_pushstring(R, lua_tostring(L, -1));
		break;
	case LUA_TNIL:
		lua_pushnil(R);
		break;
	case LUA_TTABLE:
		top = lua_gettop(L);
		lua_newtable(R);
		lua_pushnil(L);  /* first key */
		while (lua_next(L, top) != 0) {
			proxy_map(L, R, lua_gettop(R), 0);
			lua_pop(L, 1);
		}
		break;
	default:
		printf("unknown type %s\n", nam);
	}
	if (global) {
		lua_setglobal(R, nam);
		lua_pop(R, 1);
	} else
		lua_settable(R, t);

}

static void
proxy_unmap(lua_State *L, lua_State *R)
{
	proxy_object *o;

	switch (lua_type(R, -1)) {
	case LUA_TBOOLEAN:
		lua_pushboolean(L, lua_toboolean(R, -1));
		break;
	case LUA_TNUMBER:
#if LUA_VERSION_NUM >= 503
		if (lua_isinteger(R, -1))
			lua_pushinteger(L, lua_tointeger(R, -1));
		else
#endif
			lua_pushnumber(L, lua_tonumber(R, -1));
		break;
	case LUA_TSTRING:
		lua_pushstring(L, lua_tostring(R, -1));
		break;
	case LUA_TNIL:
		lua_pushnil(L);
		break;
	case LUA_TFUNCTION:
	case LUA_TTABLE:
		o = lua_newuserdata(L, sizeof(proxy_object));
		luaL_getmetatable(L, OBJECT_METATABLE);
		lua_setmetatable(L, -2);
		o->L = R;
		o->ref = luaL_ref(R, LUA_REGISTRYINDEX);
		break;
	default:
		printf("unsupported type %s\n", luaL_typename(R, -1));
	}
}

static int
proxy_newindex(lua_State *L)
{
	proxy_data *p;

	p = luaL_checkudata(L, 1, PROXY_METATABLE);
	proxy_map(L, p->L, 0, 1);
	return 0;
}

static int
object_newindex(lua_State *L)
{
	proxy_object *o;

	o = luaL_checkudata(L, -3, OBJECT_METATABLE);

	lua_rawgeti(o->L, LUA_REGISTRYINDEX, o->ref);
	proxy_map(L, o->L, lua_gettop(o->L), 0);
	lua_pop(o->L, 1);
	return 0;
}

static int
object_index(lua_State *L)
{
	proxy_object *o;

	o = luaL_checkudata(L, -2, OBJECT_METATABLE);
	lua_rawgeti(o->L, LUA_REGISTRYINDEX, o->ref);

	switch (lua_type(L, -1)) {
	case LUA_TNUMBER:
#if LUA_VERSION_NUM >= 503
		if (lua_isinteger(L, -1))
			lua_pushinteger(o->L, lua_tointeger(L, -1));
		else
#endif
			lua_pushnumber(o->L, lua_tonumber(L, -1));
		break;
	case LUA_TSTRING:
		lua_pushstring(o->L, lua_tostring(L, -1));
		break;
	default:
		return luaL_error(L, "proxy: data type '%s' is not "
		    "supported as an index value", luaL_typename(L, -1));
	}
	lua_gettable(o->L, -2);
	proxy_unmap(L, o->L);
	lua_pop(o->L, 1);
	return 1;
}

static int
object_len(lua_State *L)
{
	proxy_object *o;

	o = luaL_checkudata(L, -1, OBJECT_METATABLE);

	lua_rawgeti(o->L, LUA_REGISTRYINDEX, o->ref);
	lua_pushinteger(L, lua_rawlen(o->L, -1));
	lua_pop(o->L, 1);
	return 1;
}

static int
object_call(lua_State *L)
{
	proxy_object *o;

	o = luaL_checkudata(L, 1, OBJECT_METATABLE);
	lua_rawgeti(o->L, LUA_REGISTRYINDEX, o->ref);
	lua_pcall(o->L, 0, 0, 0);
	lua_pop(o->L, 1);
	return 0;
}

static int
proxy_dostring(lua_State *L)
{
	proxy_data *p;
	const char *chunk;

	p = luaL_checkudata(L, -2, PROXY_METATABLE);
	chunk = luaL_checkstring(L, -1);
	(void)luaL_dostring(p->L, chunk);
	/* XXX collect return values */
	return 0;
}

static void
lua_openlib(lua_State *L, const char *name, lua_CFunction fn)
{
	lua_pushcfunction(L, fn);
	lua_pushstring(L, name);
	lua_call(L, 1, 0);
}

static int
proxy_new(lua_State *L)
{
	proxy_data *p;

	p = lua_newuserdata(L, sizeof(proxy_data));
	p->L = luaL_newstate();
	p->close_on_gc = 1;
	if (p->L == NULL) {
		fprintf(stderr, "can't initialize proxy state");
		return 0;
	}
	lua_openlib(p->L, "", luaopen_base);
	lua_openlib(p->L, LUA_LOADLIBNAME, luaopen_package);
	lua_openlib(p->L, LUA_TABLIBNAME, luaopen_table);
	lua_openlib(p->L, LUA_STRLIBNAME, luaopen_string);
	lua_openlib(p->L, LUA_MATHLIBNAME, luaopen_math);
	lua_openlib(p->L, LUA_OSLIBNAME, luaopen_os);

	luaL_getmetatable(L, PROXY_METATABLE);
	lua_setmetatable(L, -2);

	return 1;
}

static void
proxy_set_info(lua_State *L)
{
	lua_pushliteral(L, "_COPYRIGHT");
	lua_pushliteral(L, "Copyright (C) 2011 - 2017 by "
	    "micro systems marc balmer");
	lua_settable(L, -3);
	lua_pushliteral(L, "_DESCRIPTION");
	lua_pushliteral(L, "State proxy for Lua");
	lua_settable(L, -3);
	lua_pushliteral(L, "_VERSION");
	lua_pushliteral(L, "proxy 1.1.5");
	lua_settable(L, -3);
}

int
luaopen_proxy(lua_State *L)
{
	struct luaL_Reg luaproxy[] = {
		{ "dostring", proxy_dostring },
		{ "new", proxy_new },
		{ NULL, NULL }
	};
	struct luaL_Reg proxy_methods[] = {
		{ "__index", proxy_index },
		{ "__newindex", proxy_newindex },
		{ "__gc", proxy_clear },
		{ NULL, NULL }
	};
	struct luaL_Reg object_methods[] = {
		{ "__index", object_index },
		{ "__newindex", object_newindex },
		{ "__len", object_len },
		{ "__call", object_call },
		{ "__gc", object_clear },
		{ NULL, NULL }
	};
	/* The PROXY metatable */
	if (luaL_newmetatable(L, PROXY_METATABLE)) {
#if LUA_VERSION_NUM >= 502
		luaL_setfuncs(L, proxy_methods, 0);
#else
		luaL_register(L, NULL, proxy_methods);
#endif
		lua_pushliteral(L, "__metatable");
		lua_pushliteral(L, "must not access this metatable");
		lua_settable(L, -3);
	}
	lua_pop(L, 1);
	if (luaL_newmetatable(L, OBJECT_METATABLE)) {
#if LUA_VERSION_NUM >= 502
		luaL_setfuncs(L, object_methods, 0);
#else
		luaL_register(L, NULL, object_methods);
#endif
		lua_pushliteral(L, "__metatable");
		lua_pushliteral(L, "must not access this metatable");
		lua_settable(L, -3);
	}
	lua_pop(L, 1);
#if LUA_VERSION_NUM >= 502
	luaL_newlib(L, luaproxy);
#else
	luaL_register(L, "proxy", luaproxy);
#endif
	proxy_set_info(L);
	return 1;
}
