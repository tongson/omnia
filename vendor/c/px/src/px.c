/***
 luaposix extensions and some unix utilities.
@module lib
*/

#define _LARGEFILE_SOURCE       1
#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "flopen.h"
#include "closefrom.h"

static int pusherror(lua_State *L, const char *error)
{
        lua_pushnil(L);
        lua_pushstring(L, error);
        return 2;
}

static int pusherrno(lua_State *L, char *error)
{
        lua_pushnil(L);
        lua_pushfstring(L, LUA_QS" : "LUA_QS, error, strerror(errno));
        lua_pushinteger(L, errno);
        return 3;
}

/***
chroot(2) wrapper.
@function chroot
@tparam string path or directory to chroot into.
@treturn bool true if successful; otherwise nil
*/
static int Cchroot(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	if (chroot(path) == -1) {
		return pusherrno(L, "chroot(2) error");
	}
	lua_pushboolean(L, 1);
	return 1;
}

/***
close(2) a file descriptor.
@function fdclose
@tparam int fd file descriptor to close
@treturn bool true if successful; otherwise nil
*/
static int Cfdclose (lua_State *L)
{
	FILE *f = *(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE);
	int res = close(fileno(f));
	if (res == -1) {
		return pusherrno(L, "close(2) error");
	}
	lua_pushboolean(L, 1);
	return 1;
}

typedef luaL_Stream LStream;
static LStream *newfile (lua_State *L)
{
	LStream *p = (LStream *)lua_newuserdata(L, sizeof(LStream));
	p->closef = NULL;
	luaL_setmetatable(L, LUA_FILEHANDLE);
	p->f = NULL;
	p->closef = &Cfdclose;
	return p;
}

/***
Wrapper to flopen(3) -- Reliably open and lock a file.
@function flopen
@tparam string file to open and lock
@treturn int a new file handle, or, in case of errors, nil plus an error message
*/
static int Cflopen(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	int flags = luaL_optinteger(L, 2, O_NONBLOCK | O_RDWR);
	mode_t mode = luaL_optinteger(L, 3, 0700);
	int fd = flopen(path, flags, mode);
	if (fd == -1) {
		return pusherrno(L, "open(2) error");
	}
	LStream *p = newfile(L);
	p->f = fdopen(fd, "rwe");
	return (p->f == NULL) ? luaL_fileresult(L, 0, NULL) : 1;
}

/***
Wrapper to fdopen(3).
@function fdopen
@tparam string file to open
@treturn int a new file handle, or, in case of errors, nil plus an error message
*/
static int Cfdopen (lua_State *L)
{
	int fd = luaL_checkinteger(L, 1);
  	const char *mode = luaL_optstring(L, 2, "re");
	LStream *p = newfile(L);
	p->f = fdopen(fd, mode);
	return (p->f == NULL) ? luaL_fileresult(L, 0, NULL) : 1;
}

/***
Wrapper to closefrom(2) -- delete open file descriptors.
@function closefrom
@tparam int fd file descriptors greater or equal to this is deleted
@treturn bool true always
*/
static int Cclosefrom (lua_State *L)
{
	int fd = luaL_optinteger(L, 2, 3);
	closefrom(fd);
	lua_pushboolean(L, 1);
	return 1;
}

/***
Wrapper to pipe2(2).
@function pipe2
@tparam int file descriptor
@treturn int fd read end descriptor
@treturn int fd write end descriptor
*/
static int Cpipe2(lua_State *L)
{
	int pipefd[2];
	int flags = luaL_checkinteger(L, 1);
	int rc = pipe2(pipefd, flags);
	if(rc < 0) {
		return pusherror(L, "pipe2(2) error");
	}
	lua_pushinteger(L, pipefd[0]);
	lua_pushinteger(L, pipefd[1]);
	return 2;
}

/* Derived from luaposix runexec(). Modified to take in the environment. */
/***
Execute a program using execve(2)
@function execve
@tparam string path of executable
@tparam table argt arguments (table can include index 0)
@tparam table arge environment
@return nil or
@treturn string error message
*/
static int Cexecve(lua_State *L)
{
	char **argv;
	char **env;
	const char *path = luaL_checkstring(L, 1);

	if (lua_type(L, 2) != LUA_TTABLE) {
		return pusherror(L, "bad argument #2 to 'execve' (table expected)");
	}

	int n = lua_rawlen(L, 2);
	argv = lua_newuserdata(L, (n + 2) * sizeof(char*));
	argv[0] = (char*) path;
	lua_pushinteger(L, 0);
	lua_gettable(L, 2);

	if (lua_type(L, -1) == LUA_TSTRING) {
		argv[0] = (char*)lua_tostring(L, -1);
	} else {
		lua_pop(L, 1);
	}

	int i;
	for (i=1; i<=n; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, 2);
		argv[i] = (char*)lua_tostring(L, -1);
	}

	argv[n+1] = NULL;

	if (lua_type(L, 3) == LUA_TTABLE) {
		int e = lua_rawlen(L, 3);
		env = lua_newuserdata(L, (e + 2) * sizeof(char*));
		for (i=0; i<=e; i++) {
			lua_pushinteger(L, i + 1);
			lua_gettable(L, 3);
			env[i] = (char*)lua_tostring(L, -1);
		}
		env[e+1] = NULL;
		execve(path, argv, env);
	} else {
		execv(path, argv);
	}
	return pusherror(L, path);
}

static const luaL_Reg syslib[] =
{
	{"chroot", Cchroot},
	{"fdclose", Cfdclose},
	{"flopen", Cflopen},
	{"closefrom", Cclosefrom},
	{"fdopen", Cfdopen},
	{"pipe2", Cpipe2},
	{"execve", Cexecve},
	{NULL, NULL}

};

int
luaopen_px(lua_State *L)
{
	luaL_newlib(L, syslib);
	return 1;
}
