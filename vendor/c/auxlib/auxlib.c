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
*strncpy_x(char* s1, const char* s2, size_t n)
{
	size_t m = strlen(s2);
	if (m > n)
	{
		m = n;
	}
	if (m != 0)
	{
		memmove(s1, s2, m);
		if (m < n)
		{
			bzero_x(s1 + m, n - m);
		}
	}
	return s1;
}

char
*strnmove(char* s1, const char* s2, size_t n)
{
	if (n > 0)
	{
        	size_t m = strlen(s2);
        	if (m + 1 > n)
		{
            		m = n - 1;
        	}
        	memmove(s1, s2, m);
        	s1[m] = 0;
    	}
    	return s1;
}
