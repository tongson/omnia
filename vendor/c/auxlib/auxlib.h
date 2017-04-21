#ifndef __AUXLIB_H__
#define __AUXLIB_H__

/*
 * _x suffix for possible conflicts with other libc symbols
 * luaX_ prefix for Lua specific symbols
 */

void bzero_x(void *, size_t);
int assert_bzero_x(unsigned char *, size_t);
int luaX_pusherror(lua_State *, const char *);
int luaX_pusherrno(lua_State *, char *);
char *strncpy_x(char *, const char *, size_t);
char *strnmove(char *, const char *, size_t);
void assertion_failed(const char *, int, const char *, const char *) __attribute((noreturn));
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define REQUIRE(cond, diag) ((void) (LIKELY(cond) || ((assertion_failed)(__FILE__, __LINE__, #diag, #cond), 0)))

#endif
