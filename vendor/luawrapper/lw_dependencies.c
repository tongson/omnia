/**
endif
 * @file lw_dependencies.c
 * @brief This file must be updated each time a new dependency to a C lua
 * library is added. For this test, no C dependency is needed
 *
 * @date 27 july 2014
 * @author carrier.nicolas0@gmail.com
 */
#include <stdlib.h>

#include "lw_dependencies.h"

#ifdef lib_lsocket
extern int luaopen_lsocket (lua_State *L);
#endif
#ifdef lib_lpeg
extern int luaopen_lpeg (lua_State *L);
#endif
#ifdef lib_linotify
extern int luaopen_inotify (lua_State *L);
#endif
#ifdef lib_luaposix
extern int luaopen_posix(lua_State *L);
extern int luaopen_posix_ctype(lua_State *L);
extern int luaopen_posix_dirent(lua_State *L);
extern int luaopen_posix_errno(lua_State *L);
extern int luaopen_posix_fcntl(lua_State *L);
extern int luaopen_posix_fnmatch(lua_State *L);
extern int luaopen_posix_getopt(lua_State *L);
extern int luaopen_posix_glob(lua_State *L);
extern int luaopen_posix_grp(lua_State *L);
extern int luaopen_posix_libgen(lua_State *L);
extern int luaopen_posix_poll(lua_State *L);
extern int luaopen_posix_pwd(lua_State *L);
extern int luaopen_posix_sched(lua_State *L);
extern int luaopen_posix_signal(lua_State *L);
extern int luaopen_posix_stdio(lua_State *L);
extern int luaopen_posix_stdlib(lua_State *L);
extern int luaopen_posix_syslog(lua_State *L);
extern int luaopen_posix_time(lua_State *L);
extern int luaopen_posix_unistd(lua_State *L);
extern int luaopen_posix_utime(lua_State *L);
extern int luaopen_posix_termio(lua_State *L);
extern int luaopen_posix_sys_msg(lua_State *L);
extern int luaopen_posix_sys_resource(lua_State *L);
extern int luaopen_posix_sys_socket(lua_State *L);
extern int luaopen_posix_sys_stat(lua_State *L);
extern int luaopen_posix_sys_statvfs(lua_State *L);
extern int luaopen_posix_sys_time(lua_State *L);
extern int luaopen_posix_sys_times(lua_State *L);
extern int luaopen_posix_sys_utsname(lua_State *L);
extern int luaopen_posix_sys_wait(lua_State *L);
#endif

const struct luaL_Reg lw_dependencies[] = {
	#ifdef lib_lsocket
	{.name = "lsocket", .func = luaopen_lsocket},
	#endif
	#ifdef lib_lpeg
        {.name = "lpeg", .func = luaopen_lpeg},
	#endif
	#ifdef lib_linotify
	{.name = "inotify", .func = luaopen_inotify},
	#endif
	#ifdef lib_luaposix
	{.name = "posix", .func = luaopen_posix},
	{.name = "posix.ctype", .func = luaopen_posix_ctype},
	{.name = "posix.dirent", .func = luaopen_posix_dirent},
	{.name = "posix.errno", .func = luaopen_posix_errno},
	{.name = "posix.fcntl", .func = luaopen_posix_fcntl},
	{.name = "posix.fnmatch", .func = luaopen_posix_fnmatch},
	{.name = "posix.getopt", .func = luaopen_posix_getopt},
	{.name = "posix.glob", .func = luaopen_posix_glob},
	{.name = "posix.grp", .func = luaopen_posix_grp},
	{.name = "posix.libgen", .func = luaopen_posix_libgen},
	{.name = "posix.poll", .func = luaopen_posix_poll},
	{.name = "posix.pwd", .func = luaopen_posix_pwd},
	{.name = "posix.sched", .func = luaopen_posix_sched},
	{.name = "posix.signal", .func = luaopen_posix_signal},
	{.name = "posix.stdio", .func = luaopen_posix_stdio},
	{.name = "posix.stdlib", .func = luaopen_posix_stdlib},
	{.name = "posix.syslog", .func = luaopen_posix_syslog},
	{.name = "posix.time", .func = luaopen_posix_time},
	{.name = "posix.unistd", .func = luaopen_posix_unistd},
	{.name = "posix.utime", .func = luaopen_posix_utime},
	{.name = "posix.termio", .func = luaopen_posix_termio},
        {.name = "posix.sys.msg", .func = luaopen_posix_sys_msg},
	{.name = "posix.sys.resource", .func = luaopen_posix_sys_resource},
	{.name = "posix.sys.socket", .func = luaopen_posix_sys_socket},
	{.name = "posix.sys.stat", .func = luaopen_posix_sys_stat},
	{.name = "posix.sys.statvfs", .func = luaopen_posix_sys_statvfs},
	{.name = "posix.sys.time", .func = luaopen_posix_sys_time},
	{.name = "posix.sys.times", .func = luaopen_posix_sys_times},
	{.name = "posix.sys.utsname", .func = luaopen_posix_sys_utsname},
	{.name = "posix.sys.wait", .func = luaopen_posix_sys_wait},
	#endif
	{.name = NULL, .func = NULL} /* NULL guard */
};

