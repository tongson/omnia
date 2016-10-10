
/*
 * _x suffix for possible conflicts with other libc symbols
 * luaX_ prefix for Lua specific symbols
 */

void bzero_x(void *ptr, size_t len);
int luaX_pusherror(lua_State *L, const char *error);
int luaX_pusherrno(lua_State *L, char *error);
char *strncpy_x(char* s1, const char* s2, size_t n);
char *strnmove(char* s1, const char* s2, size_t n);
