#ifndef __AUXLIB_H__
#define __AUXLIB_H__

/*
 * _x suffix for possible conflicts with other libc symbols
 * luaX_ prefix for Lua specific symbols
 */

void bzero_x(void *ptr, size_t len);
int luaX_pusherror(lua_State *L, const char *error);
int luaX_pusherrno(lua_State *L, char *error);
char *strncpy_x(char* s1, const char* s2, size_t n);
char *strnmove(char* s1, const char* s2, size_t n);
void assertion_failed(const char*, int, const char*, const char*) __attribute((noreturn));
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define REQUIRE(cond, diag) ((void) (LIKELY(cond) || ((assertion_failed)(__FILE__, __LINE__, #diag, #cond), 0)))

#endif
