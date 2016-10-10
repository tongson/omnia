#include <string.h>
#include <errno.h>

#include <lua.h>
#include <lauxlib.h>

/*
 * From: https://boringssl.googlesource.com/boringssl/+/ad1907fe73334d6c696c8539646c21b11178f20f
 * Tested with GCC and clang at -O3
 */

void
bzero_x(void *ptr, size_t len)
{
	memset(ptr, 0, len);
	__asm__ __volatile__("" : : "r"(ptr) : "memory");
}

int
luaX_pusherror(lua_State *L, const char *error)
{
        lua_pushnil(L);
        lua_pushstring(L, error);
        return 2;
}

int
luaX_pusherrno(lua_State *L, char *error)
{
        lua_pushnil(L);
        lua_pushfstring(L, LUA_QS" : "LUA_QS, error, strerror(errno));
        lua_pushinteger(L, errno);
        return 3;
}

char
*strncpy_x(char *dest, const char *src, size_t n)
{
	size_t len = strlen(src);
	if (len > n)
	{
		len = n;
	}
	if (len != 0)
	{
		memmove(dest, src, len);
		if (len < n)
		{
			bzero_x(s1 + len, n - len);
		}
	}
	return dest;
}

char
*strnmove(char *dest, const char *src, size_t n)
{
	if (n > 0)
	{
		size_t len = strlen(src);
		if (len + 1 > n)
		{
			len = n - 1;
		}
		if (len != 0)
			memmove(dest, src, len);
			dest[len] = 0;
		}
	}
	return dest;
}
