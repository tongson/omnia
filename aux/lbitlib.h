#define luaL_checkunsigned(L,a) ((lua_Unsigned)luaL_checkinteger(L,a))
#define luaL_optunsigned(L,a,d) \
            ((lua_Unsigned)luaL_optinteger(L,a,(lua_Integer)(d)))
#define lua_pushunsigned(L,n)   lua_pushinteger(L, (lua_Integer)(n))
