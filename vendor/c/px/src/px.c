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
#include <spawn.h>
#include <sys/poll.h>
#include <sys/wait.h>

#include <sys/types.h>
#include <sys/stat.h>

/*
 * lclonetable
 */
#include <lobject.h>
#include <ltable.h>
#include <lgc.h>
#include <lstate.h>
#define black2gray(x)	resetbit(x->marked, BLACKBIT)
#define linkgclist(o,p)	((o)->gclist = (p), (p) = obj2gco(o))

/*
 * lcleartable
 */
#define gnodelast(h)    gnode(h, cast(size_t, sizenode(h)))
#define dummynode               (&dummynode_)
static const Node dummynode_ = {
	{NILCONSTANT},  /* value */
	{{NILCONSTANT, 0}}  /* key */
};

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "auxlib.h"

#include "flopen.h"
#include "closefrom.h"

static int
is_file(const char *path)
{
    struct stat path_stat;
    stat(path, &path_stat);
    return S_ISREG(path_stat.st_mode);
}

static int
lcleartable(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	Table *h = (Table *)lua_topointer(L, 1);
	unsigned int i;
	for (i = 0; i < h->sizearray; i++)
		setnilvalue(&h->array[i]);
	if (h->node != dummynode) {
		Node *n, *limit = gnodelast(h);
		for (n = gnode(h, 0); n < limit; n++)   //traverse hash part
			setnilvalue(gval(n));
	}
	return 0;
}

/*
 * From:
 * http://lua-users.org/lists/lua-l/2017-07/msg00075.html
 * https://gist.github.com/cloudwu/a48200653b6597de0446ddb7139f62e3
 */
static void
barrierback(lua_State *L, Table *t)
{
	if (isblack(t)) {
		global_State *g = G(L);
		black2gray(t);  /* make table gray (again) */
		linkgclist(t, g->grayagain);
	}
}

static int
lclonetable(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TTABLE);
	luaL_checktype(L, 2, LUA_TTABLE);
	Table * to = (Table *)lua_topointer(L, 1);
	const Table * from = lua_topointer(L, 2);
	void *ud;
	lua_Alloc alloc = lua_getallocf(L, &ud);
	if (from->lsizenode != to->lsizenode) {
		if (isdummy(from)) {
			// free to->node
			if (!isdummy(to))
				alloc(ud, to->node, sizenode(to) * sizeof(Node), 0);
			to->node = from->node;
		} else {
			unsigned int size = sizenode(from) * sizeof(Node);
			Node *node = alloc(ud, NULL, 0, size);
			if (node == NULL)
				luaL_error(L, "Out of memory");
			memcpy(node, from->node, size);
			// free to->node
			if (!isdummy(to))
				alloc(ud, to->node, sizenode(to) * sizeof(Node), 0);
			to->node = node;
		}
		to->lsizenode = from->lsizenode;
	} else if (!isdummy(from)) {
		unsigned int size = sizenode(from) * sizeof(Node);
		if (isdummy(to)) {
			Node *node = alloc(ud, NULL, 0, size);
			if (node == NULL)
				luaL_error(L, "Out of memory");
			to->node = node;
		}
		memcpy(to->node, from->node, size);
	}
	if (from->lastfree) {
		int lastfree = from->lastfree - from->node;
		to->lastfree = to->node + lastfree;
	} else {
		to->lastfree = NULL;
	}
	if (from->sizearray != to->sizearray) {
		if (from->sizearray) {
			TValue *array = alloc(ud, NULL, 0, from->sizearray * sizeof(TValue));
			if (array == NULL)
				luaL_error(L, "Out of memory");
			alloc(ud, to->array, to->sizearray * sizeof(TValue), 0);
			to->array = array;
		} else {
			alloc(ud, to->array, to->sizearray * sizeof(TValue), 0);
			to->array = NULL;
		}
		to->sizearray = from->sizearray;
	}
	memcpy(to->array, from->array, from->sizearray * sizeof(TValue));
	barrierback(L,to);
	lua_settop(L, 1);
	return 1;
}

static int
Chostname(lua_State *L)
{
        char hostname[1026]; // NI_MAXHOST + 1
        size_t len = 1025;
        if (!gethostname(hostname, len)) {
                hostname[1025] = '\0';
                lua_pushstring(L, hostname);
        } else {
                return luaX_pusherror(L, "gethostname(2) error");
        }
        return 1;
}

/***
chroot(2) wrapper.
@function chroot
@tparam string path or directory to chroot into.
@treturn bool true if successful; otherwise nil
*/
static int
Cchroot(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	errno = 0;
	if (0 > chroot(path)) {
		return luaX_pusherror(L, "chroot(2) error");
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
static int
Cfdclose (lua_State *L)
{
	FILE *f = *(FILE**)luaL_checkudata(L, 1, LUA_FILEHANDLE);
	errno = 0;
	if (0 > close(fileno(f))) {
		return luaX_pusherror(L, "close(2) error");
	}
	lua_pushboolean(L, 1);
	return 1;
}

typedef luaL_Stream LStream;
static
LStream *newfile (lua_State *L)
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
static int
Cflopen(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	int flags = luaL_optinteger(L, 2, O_NONBLOCK | O_RDWR);
	int fd = flopen(path, flags, 0700);
	LStream *p = newfile(L);
	if (0 > fd) {
		errno = 0;
		return luaX_pusherror(L, "flopen(2) error");
	}
	p->f = fdopen(fd, "rwe");
	return (p->f == NULL) ? luaL_fileresult(L, 0, NULL) : 1;
}

/***
Wrapper to fdopen(3).
@function fdopen
@tparam string file to open
@treturn int a new file handle, or, in case of errors, nil plus an error message
*/
static int
Cfdopen (lua_State *L)
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
static int
Cclosefrom (lua_State *L)
{
	int fd = luaL_optinteger(L, 2, 3);
	closefrom(fd);
	lua_pushboolean(L, 1);
	return 1;
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
static int
Cexecve(lua_State *L)
{
	char **argv;
	char **env;
	const char *path = luaL_checkstring(L, 1);
	int n;
	int i;
	if (LUA_TTABLE != lua_type(L, 2)) {
		errno = 0;
		return luaX_pusherror(L, "bad argument #2 to 'execve' (table expected)");
	}
	n = lua_rawlen(L, 2);
	argv = lua_newuserdata(L, (n+2)*sizeof(char*));
	argv[0] = (char*)path;
	lua_pushinteger(L, 0);
	lua_gettable(L, 2);
	if (LUA_TSTRING == lua_type(L, -1)) {
		argv[0] = (char*)lua_tostring(L, -1);
	} else {
		lua_pop(L, 1);
	}
	for (i=1; i<=n; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, 2);
		argv[i] = (char*)lua_tostring(L, -1);
	}
	argv[n+1] = 0;
	if (LUA_TTABLE != lua_type(L, 3)) {
		errno = 0;
		if (0 > execv(path, argv)) return luaX_pusherror(L, "execv(3) error");
	} else if (LUA_TTABLE == lua_type(L, 3)) {
		int e = lua_rawlen(L, 3);
		int ei;
		env = lua_newuserdata(L, (e+2)*sizeof(char*));
		for (ei=0; ei<=e; ei++) {
			lua_pushinteger(L, ei+1);
			lua_gettable(L, 3);
			env[ei] = (char*)lua_tostring(L, -1);
		}
		env[e+1] = 0;
		errno = 0;
		if (0 > execve(path, argv, env)) return luaX_pusherror(L, "execve(2) error");
	}	else {
		errno = 0;
		return luaX_pusherror(L, "bad argument #3 to 'execve' (none or table expected)");
	}
	return 0;
}

static int
Cposix_spawn(lua_State *L)
{
	int nargs = lua_gettop(L);
	char **argv;
	char **env;
	const char *path = luaL_checkstring(L, 1);
	if (!is_file(path)) return luaX_pusherror(L, "bad argument #1 to 'posix_spawn' (valid path expected)");
	if (LUA_TTABLE != lua_type(L, 2)) {
		errno = 0;
		return luaX_pusherror(L, "bad argument #2 to 'posix_spawn' (table expected)");
	}
	{
		// arg #2 (table) copied to argv[]
		int n = lua_rawlen(L, 2);
		argv = lua_newuserdata(L, (n+2)*sizeof(char*));
		argv[0] = (char *)path;
		if (1 < nargs) {
			int i;
			for (i=1; i<=n; i++) {
				lua_pushinteger(L, i);
				lua_gettable(L, 2);
				argv[i] = (char*)lua_tostring(L, -1);
				lua_pop(L, 1);
			}
		}
		argv[n+1] = 0;
	}
	{
		// arg #3 (table) copied to env[]
		int e = lua_rawlen(L, 3);
		env = lua_newuserdata(L, (e+1)*sizeof(char*));
		if (LUA_TTABLE == lua_type(L, 3)) {
			int ei;
			for (ei=0; ei<=e; ei++) {
				lua_pushinteger(L, ei+1);
				lua_gettable(L, 3);
				env[ei] = (char*)lua_tostring(L, -1);
				lua_pop(L, 1);
			}
			env[e+1] = 0;
		} else {
			env[0] = 0;
		}
	}

	int stdin[2] ;
	int poll_stdin = 0;
	posix_spawn_file_actions_t action = {0};
	pid_t pid;
	int status;
	errno = 0;
	if (pipe(stdin)) return luaX_pusherror(L, "pipe(2) error.");
	if (0 != posix_spawn_file_actions_init(&action)) goto error;

	if (3 < nargs) {
		lua_pushliteral(L, "stdin");
		lua_gettable(L, 4);
		if (LUA_TSTRING == lua_type(L, -1)) {
			if (0 != posix_spawn_file_actions_addclose(&action, stdin[1])) goto error;
			if (0 != posix_spawn_file_actions_adddup2(&action, stdin[0], 0)) goto error;
			if (0 != posix_spawn_file_actions_addclose(&action, stdin[0])) goto error;
			lua_pop(L, 1);
			poll_stdin = 1;
		}
		lua_pushliteral(L, "stdout");
		lua_gettable(L, 4);
		if (LUA_TSTRING == lua_type(L, -1)) {
			if (0 != posix_spawn_file_actions_addopen(&action, 1, lua_tostring(L, -1), (O_WRONLY | O_CREAT | O_TRUNC), 0600)) goto error;
			lua_pop(L, 1);
		} else {
			if (0 != posix_spawn_file_actions_addopen(&action, 1, "/dev/null", O_WRONLY, 0600)) goto error;
		}
		lua_pushliteral(L, "stderr");
		lua_gettable(L, 4);
		if (LUA_TSTRING == lua_type(L, -1)) {
			if (0 != posix_spawn_file_actions_addopen(&action, 2, lua_tostring(L, -1), (O_WRONLY | O_CREAT | O_TRUNC), 0600)) goto error;
			lua_pop(L, 1);
		} else {
			if (0 != posix_spawn_file_actions_addopen(&action, 2, "/dev/null", O_WRONLY, 0600)) goto error;
		}
	} else {
		if (0 != posix_spawn_file_actions_addopen(&action, 0, "/dev/null", O_RDONLY, 0600)) goto error;
		if (0 != posix_spawn_file_actions_addopen(&action, 1, "/dev/null", O_WRONLY, 0600)) goto error;
		if (0 != posix_spawn_file_actions_addopen(&action, 2, "/dev/null", O_WRONLY, 0600)) goto error;
	}

	int r;
	while (1) {
		errno = 0;
		r = posix_spawn(&pid, argv[0], &action, NULL, argv, env);
		if (0 == r) break;
		if (3 < nargs) {
			lua_pushstring(L, "ignore");
			lua_gettable(L, 4);
			if (lua_toboolean(L, -1)) {
				lua_pop(L, 1);
				break;
			}
		}
		if (0 > r) goto error;
		if ((0 > r) && (EINTR == errno)) continue;
	}
	{
		int timeout = -1;
		if (3 < nargs) {
			lua_pushstring(L, "timeout");
			lua_gettable(L, 4);
			if (LUA_TNUMBER == lua_type(L, -1)) {
				timeout = (int)lua_tointeger(L, -1);
			}
			lua_pop(L, 1);
		}

		struct pollfd fd0[1];
		fd0[0].fd = stdin[1];
		fd0[0].events = POLLOUT;
		while(poll_stdin)  {
			errno = 0;
			int pr = poll(fd0, 1, timeout);
			if (0 < pr) {
				if (fd0[0].revents & POLLOUT) {
						fd0[0].revents = 0;
						lua_pushliteral(L, "stdin");
						lua_gettable(L, 4);
						int sz = lua_rawlen(L, -1);
						ssize_t wr;
						while (1) {
							errno = 0;
							wr = write(stdin[1], lua_tostring(L, -1), sz);
							if (0 < wr) break;
							if (0 > wr && (EAGAIN == errno)) continue;
							if (0 > wr && (EINTR == errno)) continue;
							if (0 > wr) goto error;
							if (0 == wr) return luaX_pusherror(L, "0 bytes written to stdin.");
						}
						lua_pop(L, 1);
						close(stdin[0]);
						close(stdin[1]);
						poll_stdin = 0;
				}
			}
			if ((0 > pr) && (EINTR == errno)) continue;
			if (0 > pr) goto error;
			if (0 == pr) {
				errno = 0;
				return luaX_pusherror(L, "Execution timed out.");
			}
		}
	}

	while(1) {
		int w = waitpid(pid, &status, 0);
		if (0 < w) break;
		if (0 == w || EINTR == errno) continue;
	}
	posix_spawn_file_actions_destroy(&action);
	lua_createtable(L, 0, 3);
	if (WIFEXITED(status)) {
                lua_pushliteral(L,"exited");
		lua_setfield(L, -2, "status");
                lua_pushinteger(L, WEXITSTATUS(status));
		lua_setfield(L, -2, "code");
        } else if (WIFSIGNALED(status)) {
                lua_pushliteral(L,"killed");
		lua_setfield(L, -2, "status");
                lua_pushinteger(L, WTERMSIG(status));
		lua_setfield(L, -2, "code");
        } else if (WIFSTOPPED(status)) {
                lua_pushliteral(L,"stopped");
		lua_setfield(L, -2, "status");
                lua_pushinteger(L, WSTOPSIG(status));
		lua_setfield(L, -2, "code");
        }
	lua_pushinteger(L, (lua_Integer)pid);
	lua_setfield(L, -2, "pid");
	lua_settop(L, -1);
	return 1;
error:
	{
		int saved = errno;
		close(stdin[0]);
		close(stdin[1]);
		errno = saved;
		posix_spawn_file_actions_destroy(&action);
		return luaX_pusherror(L, "Error encountered.");
	}
}

static const
luaL_Reg syslib[] =
{
	{"hostname", Chostname},
	{"chroot", Cchroot},
	{"fdclose", Cfdclose},
	{"flopen", Cflopen},
	{"closefrom", Cclosefrom},
	{"fdopen", Cfdopen},
	{"execve", Cexecve},
	{"posix_spawn", Cposix_spawn},
	{"table_copy", lclonetable},
	{"table_clear", lcleartable},
	{NULL, NULL}
};

int
luaopen_px(lua_State *L)
{
	luaL_newlib(L, syslib);
	return 1;
}
