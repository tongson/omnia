#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/select.h>

#include <lua.h>
#include <lauxlib.h>
#include <auxlib.h>

#define BUFSZ 4096
#define MAXURI 2048

/***
  Dumb and minimal HTTP client.
  @module qhttp
*/

/***
Simple HTTP GET to an IP
@function get
@string HTTP server IP
@string URI to request
@treturn string server reply
*/
static int
get(lua_State *L)
{
	const char *arg_ip = luaL_checkstring(L, 1);
	const char *uri = luaL_checkstring(L, 2);
	char ip[16] = {0};
	int fd, read;
	struct sockaddr_in target = {0};
	char buf[BUFSZ] = {0};
	size_t len;
	if ((len = strlen(arg_ip)) > 15) {
		return luaX_pusherror(L, "IP argument cannot exceed 15 characters.");
	}
	if ((len = strlen(uri)) > MAXURI) {
		return luaX_pusherror(L, "URI too long.");
	}
	strnmove(ip, arg_ip, 16);
	target.sin_family = AF_INET;
	target.sin_port = htons(80);
	if (inet_pton(AF_INET, ip, &target.sin_addr.s_addr) == 0) {
		return luaX_pusherror(L, "inet_pton(3) error. Invalid IP address.");
	}
	if ((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
		return luaX_pusherrno(L, "socket(2) error.");
	}

	struct timeval timeout;
	timeout.tv_sec = 10;
	timeout.tv_usec = 0;
	fd_set set;
	FD_ZERO(&set);
	FD_SET(fd, &set);
	fcntl(fd, F_SETFL, O_NONBLOCK);
	if (connect(fd, (struct sockaddr*)&target, sizeof(target)) != 0) {
		if (errno != EINPROGRESS) {
			return luaX_pusherrno(L, "connect(2) error.");
		}
	}
	int status;
	status = select(fd + 1, NULL, &set, NULL, &timeout);
	if (status == 0) {
		return luaX_pusherror(L, "select(2) timeout.");
	}
	if (status < 0) {
		return luaX_pusherrno(L, "select(2) error.");
	}
	fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) & ~O_NONBLOCK);

	ssize_t send_bytes = strlen(uri) + 19;
	ssize_t sent_bytes;
	ssize_t total_bytes;
	if (snprintf(buf, send_bytes, "GET %s HTTP/1.0\r\n\r\n\r\n\r\n", uri) < 0) {
		return luaX_pusherror(L, "snprintf(2) error.");
	}
	while (1) {
	if ((sent_bytes = send(fd, buf, send_bytes, 0)) < 0) {
		return luaX_pusherrno(L, "send(2) error.");
	}
		total_bytes += sent_bytes;
		if (total_bytes >= send_bytes) {
			break;
		}
	}

	lua_settop(L, 0);
	while (1) {
		bzero_x(buf, BUFSZ);
		REQUIRE(assert_bzero_x(buf, BUFSZ) == 0, "bzero_x() failed. Compiler behavior changed!");
		read = recv(fd, buf, sizeof(buf), 0);
		if (read > 0) {
			lua_pushlstring(L, buf, read);
			lua_checkstack(L, 1);
		} else {
			break;
		}
	}

	close(fd);
	int n = lua_gettop(L);
	lua_concat(L, n);
	return 1;
}

static const
luaL_Reg qhttp_funcs[] =
{
	{"get", get},
	{0, 0}
};

int
luaopen_qhttp(lua_State *L)
{
	luaL_newlib(L, qhttp_funcs);
	return 1;
}
