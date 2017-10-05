#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

#include <lua.h>
#include <lauxlib.h>

void
auxI_assertion_failed(const char *file, int line, const char *diag, const char *cond)
{
	fprintf(stderr, "Assertion failed on %s line %d: %s\n", file, line, cond);
	fprintf(stderr, "Diagnostic: %s\n", diag);
	(void)fflush(stderr);
	abort();
}

/*
 * From: https://boringssl.googlesource.com/boringssl/+/ad1907fe73334d6c696c8539646c21b11178f20f
 * Tested with GCC and clang at -O3
 */

void
auxL_bzero(void *ptr, size_t len)
{
	memset(ptr, 0, len);
	__asm__ __volatile__("" : : "r"(ptr) : "memory");
}

int
auxL_assert_bzero(char *buf, size_t len)
{
	int z = 0;
	size_t i;
	for (i = 0; i < len; ++i)
		z |= buf[i];
	return z != 0;
}

char
*auxL_strncpy(char *dest, const char *src, size_t n)
{
	size_t len = strlen(src);
	if (len != 0) {
		if (len > n) {
			len = n;
		}
		memmove(dest, src, len);
		if (len < n) {
			auxL_bzero(dest + len, n - len);
		}
	}
	return dest;
}

char
*auxL_strnmove(char *dest, const char *src, size_t n)
{
	if (n > 0) {
		size_t len = strlen(src);
		if (len != 0) {
			if (len + 1 > n) {
				len = n - 1;
			}
			memmove(dest, src, len);
			dest[len] = '\0';
		}
	}
	return dest;
}

int
luaX_pusherror(lua_State *L, char *error)
{
	lua_pushnil(L);
	if (errno) {
		lua_pushfstring(L, LUA_QS" : "LUA_QS, error, strerror(errno));
		lua_pushinteger(L, errno);
		return 3;
	} else {
		lua_pushstring(L, error);
		return 2;
	}
}

static int
luaX_assert(lua_State *L)
{
	const char *msg;
	msg = 0;
	int fargs = lua_gettop(L);
	if (fargs >= 2) {
		msg = lua_tolstring(L, 2, 0);
	}
	if (lua_toboolean(L, 1)) {
		return fargs;
	} else {
		luaL_checkany(L, 1);
		lua_remove(L, 1);
		lua_Debug info;
		lua_getstack(L, 1, &info);
		const char *failed = "Assertion failed";
		if (!msg) {
			msg = "false";
		}
		const char *name;
		name = 0;
		lua_getinfo(L, "Snl", &info);
		if (info.name) {
			name = info.name;
		} else {
			name = "?";
		}
		lua_pushfstring(L, "%s:<%s.lua:%d:%s:%s> %s", \
				failed, info.source, info.currentline, info.namewhat, name,  msg);
		return lua_error(L);
	}
}

static const
luaL_Reg auxlib_funcs[] =
{
        {"assert", luaX_assert},
        {NULL, NULL}
};

int
luaopen_auxlib(lua_State *L)
{
        luaL_newlib(L, auxlib_funcs);
        return 1;
}
