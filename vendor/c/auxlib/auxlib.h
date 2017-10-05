#ifndef __AUXLIB_H__
#define __AUXLIB_H__

/*
 * auxL_ prefix for possible conflicts with other libc symbols
 * auxI_ same as above but for internal use
 * luaX_ prefix for Lua specific symbols
 */

void auxL_bzero(void *, size_t);
int auxL_assert_bzero(char *, size_t);
int luaX_pusherror(lua_State *, char *);
char *auxL_strncpy(char *, const char *, size_t);
char *auxL_strnmove(char *, const char *, size_t);
void auxI_assertion_failed(const char *, int, const char *, const char *) __attribute((noreturn));
#define LIKELY(x) __builtin_expect(!!(x), 1)
#define REQUIRE(cond, diag) ((void) (LIKELY(cond) || ((auxI_assertion_failed)(__FILE__, __LINE__, #diag, #cond), 0)))

#endif
