#include <lua.h>
#include <lauxlib.h>
#include <auxlib.h>

#include <sys/prctl.h>
#include <linux/prctl.h>

static int
set_name(lua_State *L)
{
	const char *name = luaL_checkstring(L, 1);
	/* Only allowed up to 16 bytes including NUL terminator */
	size_t len = strlen(name);
	if (len > 15) {
		return luaX_pusherror(L, "Argument to prctl.set_name() cannot exceed 15 characters.");
	}
	char psname[16];
	auxL_strnmove(psname, name, 15);
	if (prctl(PR_SET_NAME, (char *) psname, 0, 0, 0) == -1) {
		return luaX_pusherrno(L, "prctl(2) error");
	}
	return 1;
}


static const
luaL_Reg prctl_funcs[] =
{
	{"set_name", set_name},
	{NULL, NULL}
};

int
luaopen_prctl(lua_State *L)
{
	luaL_newlib(L, prctl_funcs);
	return 1;
}
