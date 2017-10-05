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

#define TIMEOUT 10
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
	int saved_errno;
	int zero = 0;
	const char *arg_ip;
	const char *arg_host;
	const char *arg_uri;
	if (3 == lua_gettop(L)) {
		arg_ip = luaL_checkstring(L, 1);
		arg_host = luaL_checkstring(L, 2);
		arg_uri = luaL_checkstring(L, 3);
	} else if (2 == lua_gettop(L)) {
		zero = 1;
		arg_ip = luaL_checkstring(L, 1);
		arg_uri = luaL_checkstring(L, 2);
		arg_host = '\0';
	} else {
		errno = 0;
		return luaX_pusherror(L, "Invalid number of arguments.");
	}

	errno = 0;
	if (15 < strlen(arg_ip)) return luaX_pusherror(L, "IP argument cannot exceed 15 characters.");
	if (MAXURI < strlen(arg_uri)) return luaX_pusherror(L, "URI too long.");
	char ip[16] = {0};
	auxL_strnmove(ip, arg_ip, 16);
	struct sockaddr_in target = {0};
	target.sin_family = AF_INET;
	target.sin_port = htons(80);
	errno = 0;
	if (1 != inet_pton(AF_INET, ip, &target.sin_addr.s_addr)) return luaX_pusherror(L, "Invalid IP address.");
	errno = 0;
	int fd = socket(AF_INET, SOCK_STREAM, 0);
	if (0 > fd) goto error;
	struct timeval timeout = {0};
	timeout.tv_sec = TIMEOUT;
	timeout.tv_usec = 0;
	fd_set set;
	FD_ZERO(&set);
	FD_SET(fd, &set);
	errno = 0;
	if (0 > fcntl(fd, F_SETFL, O_NONBLOCK)) goto error;
	errno = 0;
	if (0 > connect(fd, (struct sockaddr*)&target, sizeof(target))) {
		if (EINPROGRESS != errno) goto error;
		errno = 0;
		int select_r = select(fd+1, NULL, &set, NULL, &timeout);
		if (!select_r) {
			saved_errno = errno;
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = saved_errno;
			return luaX_pusherror(L, "select(2) timed out in qhttp.get().");
		}
		if (0 > select_r) goto error;
		while (!FD_ISSET(fd, &set)) continue;
		int connect_e = 0;
		socklen_t connect_len = sizeof(connect_e);
		errno = 0;
		if (0 > getsockopt(fd, SOL_SOCKET, SO_ERROR, &connect_e, &connect_len)) goto error;
		errno = connect_e;
		if (connect_e) goto error;
	}
	errno = 0;
	if (0 > fcntl(fd, F_SETFL, (fcntl(fd, F_GETFL, 0) & ~O_NONBLOCK))) goto error;

	char buf[BUFSZ] = {0};
	ssize_t send_bytes;
	errno = 0;
	if (!zero) {
		send_bytes = strlen(arg_uri) + strlen(arg_host) + 46;
		if (0 > snprintf(buf, send_bytes,
					"GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n\r\n", arg_uri, arg_host)) goto error;
	} else {
		send_bytes = strlen(arg_uri) + 21;
		if (0 > snprintf(buf, send_bytes, "GET %s HTTP/1.0\r\n\r\n\r\n\r\n", arg_uri)) goto error;
	}
	ssize_t total_bytes = 0;
	for (ssize_t s = 0;;) {
		errno = 0;
		s = send(fd, buf, send_bytes, 0);
		if (0 > s) goto error;
		total_bytes += s;
		if (total_bytes >= send_bytes) {
			break;
		}
	}
	lua_settop(L, 0);
  for (ssize_t r = 0;;) {
		auxL_bzero(buf, BUFSZ);
		REQUIRE(auxL_assert_bzero(buf, BUFSZ) == 0, "auxL_bzero() failed. Compiler behavior changed!");
		errno = 0;
		r = recv(fd, buf, BUFSZ, 0);
		if (0 < r) {
			lua_pushlstring(L, buf, (size_t)r);
			lua_checkstack(L, 1);
		} else if (0 == r) {
			break;
		} else {
			goto error;
		}
	}
	shutdown(fd, SHUT_RDWR);
	close(fd);
	int luabuf_sz = lua_gettop(L);
	lua_concat(L, luabuf_sz);
	return 1;
error:
	saved_errno = errno;
	shutdown(fd, SHUT_RDWR);
	close(fd);
	errno = saved_errno;
	return luaX_pusherror(L, "Encountered error in qhttp.get().");
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
