#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <netdb.h>

#include <lua.h>
#include <lauxlib.h>
#include <auxlib.h>

#define BUFSZ 4096
#define TIMEOUT 10

static int
udp(lua_State *L)
{
	errno = 0;
	const char *ip = luaL_checkstring(L, 1);
	lua_Number port = luaL_checknumber(L, 2);
	const char *payload;
	size_t payload_sz;
	char buf[BUFSZ] = {0};
	char rbuf[BUFSZ] = {0};
	struct timeval tv = {0};
	struct sockaddr_in dst = {0};
	struct sockaddr_in src = {0};
	struct sockaddr_in resp_src = {0};
	time_t start;
	time_t now;
	int fd;
	socklen_t socklen;
	fd_set set;
	int select_r;
	ssize_t recvfrom_r;
	int saved;

	if (2 > lua_gettop(L)) return luaX_pusherror(L, "Not enough arguments.");
	dst.sin_family = AF_INET;
	dst.sin_port = htons(port);
	errno = 0;
	if (1 != inet_pton(AF_INET, ip, &dst.sin_addr.s_addr)) return luaX_pusherror(L, "Invalid IP address passed.");
	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (0 > fd) goto error;
	src.sin_family = AF_INET;
	src.sin_addr.s_addr = htonl(INADDR_ANY);
	src.sin_port = htons(0);
	errno = 0;
	if (0 > bind(fd, (struct sockaddr *)&src, sizeof(src))) goto error;
	if (3 == lua_gettop(L)) {
		payload = luaL_checkstring(L, 3);
		payload_sz = lua_rawlen(L, 3);
		if (payload_sz > BUFSZ) payload_sz = BUFSZ;
		memcpy(buf, payload, payload_sz);
	} else {
		payload_sz = 1;
		buf[0] = '\0';
	}

	errno = 0;
	if (0 > sendto(fd, buf, payload_sz, 0, (struct sockaddr *)&dst, sizeof(dst))) goto error;

	time(&start);
	while(1) {
		tv = (struct timeval){0};
		time(&now);
		if (TIMEOUT <= now-start) {
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = 0;
			return luaX_pusherror(L, "qsocket.udp() timed out.");
		}
		tv.tv_sec = TIMEOUT-(now-start);
		tv.tv_usec = 0;
		FD_ZERO(&set);
		FD_SET(fd, &set);
		errno = 0;
		select_r = select(fd+1, &set, NULL, NULL, &tv);
		if (!select_r) {
			saved = errno;
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = saved;
			return luaX_pusherror(L, "select(2) timed out.");
		}
		if (0 > select_r) goto error;
		if(!FD_ISSET(fd, &set)) continue;
		socklen = sizeof(struct sockaddr_in);
		errno = 0;
		recvfrom_r = recvfrom(fd, rbuf, BUFSZ, 0, (struct sockaddr *)&resp_src, &socklen);
		saved = errno;
		shutdown(fd, SHUT_RDWR);
		close(fd);
		errno = saved;
		if (0 > recvfrom_r) return luaX_pusherror(L, "recvfrom(2) error in udp().");
		lua_pushlstring(L, rbuf, (size_t)recvfrom_r);
		lua_pushstring(L, inet_ntoa(resp_src.sin_addr));
		lua_pushinteger(L, htons(resp_src.sin_port));
		return 3;
	}
error:
	saved = errno;
	shutdown(fd, SHUT_RDWR);
	close(fd);
	errno = saved;
	return luaX_pusherror(L, "Encountered error in qsocket.udp().");
}

static int
tcp(lua_State *L)
{
	errno = 0;
	const char *arg_ip = luaL_checkstring(L, 1);
	char ip[16] = {0};
	lua_Number port = luaL_checknumber(L, 2);
	const char *payload;
	char payload_buf[BUFSZ] = {0};
	size_t payload_sz;

	struct timeval tv = {0};
	struct sockaddr_in dst = {0};

	ssize_t recv_r;
	char recv_buf[BUFSZ] = {0};
	int fd;
	fd_set set;
	int select_r;
	int connect_e;
	int luabuf_sz;
	int saved;
	socklen_t connect_len;
	int zero = 0;

	if (lua_gettop(L) < 2) return luaX_pusherror(L, "Not enough arguments.");
	if (arg_ip[0] != '-') {
		auxL_strnmove(ip, arg_ip, 16);
	} else {
		zero = 1;
		auxL_strnmove(ip, arg_ip+1, 16);
	}
	if (15 < strlen(ip)) return luaX_pusherror(L, "IP argument cannot exceed 15 characters.");
  dst.sin_family = AF_INET;
	dst.sin_port = htons(port);
	if (1 != inet_pton(AF_INET, ip, &dst.sin_addr.s_addr)) return luaX_pusherror(L, "Invalid IP address passed.");
	if (3 == lua_gettop(L) && lua_isstring(L, 3)) {
		payload = luaL_checkstring(L, 3);
		payload_sz = lua_rawlen(L, 3);
		if (payload_sz > BUFSZ) payload_sz = BUFSZ;
		memcpy(payload_buf, payload, payload_sz);
	} else {
		payload_sz = 1;
		payload_buf[0] = '\0';
	}
	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (0 > fd) return luaX_pusherror(L, "Cannot create FD from socket(2) in qsocket.tcp().");
	if (0 > fcntl(fd, F_SETFL, O_NONBLOCK)) goto error;
	if (0 > connect(fd, (struct sockaddr*)&dst, sizeof(dst))) {
		if (EINPROGRESS != errno) goto error;
		tv.tv_sec = TIMEOUT;
		tv.tv_usec = 0;
		FD_ZERO(&set);
		FD_SET(fd, &set);
		errno = 0;
		select_r = select(fd+1, NULL, &set, NULL, &tv);
		if (!select_r) {
			saved = errno;
			shutdown(fd, SHUT_RDWR);
			close(fd);
			errno = saved;
			return luaX_pusherror(L, "'select(2) timed out in qsocket.tcp().' : 'Connection timed out.'");
		}
		if (0 > select_r) goto error;
		while(!FD_ISSET(fd, &set)) continue;
		connect_e = 0;
		connect_len = sizeof(connect_e);
		errno = 0;
		if (0 > getsockopt(fd, SOL_SOCKET, SO_ERROR, &connect_e, &connect_len)) goto error;
		errno = connect_e;
		if (connect_e) goto error;
	}
	if (zero) {
		shutdown(fd, SHUT_RDWR);
		close(fd);
		lua_pushboolean(L, 1);
		return 1;
	}
	errno = 0;
	if (0 > fcntl(fd, F_SETFL, (fcntl(fd, F_GETFL, 0) & ~O_NONBLOCK))) goto error;
	if (0 > send(fd, payload_buf, payload_sz, 0)) goto error;
	lua_settop(L, 0);
	while (1) {
		auxL_bzero(recv_buf, BUFSZ);
		REQUIRE(auxL_assert_bzero(recv_buf, BUFSZ) == 0, "auxL_bzero() failed. Compiler behavior changed!");
		errno = 0;
		recv_r = recv(fd, recv_buf, BUFSZ, MSG_DONTWAIT);
		if (0 > recv_r && (EAGAIN == errno || EWOULDBLOCK == errno)) {
			errno = 0;
			continue;
		} else if (0 < recv_r) {
			lua_pushlstring(L, recv_buf, (size_t)recv_r);
			lua_checkstack(L, 1);
		} else if (0 == recv_r) {
			break;
		} else {
			goto error;
		}
	}
	shutdown(fd, SHUT_RDWR);
	close(fd);
	luabuf_sz = lua_gettop(L);
	lua_concat(L, luabuf_sz);
	return 1;
error:
	saved = errno;
	shutdown(fd, SHUT_RDWR);
	close(fd);
	errno = saved;
	return luaX_pusherror(L, "Encountered error in qsocket.tcp().");
}

static const
luaL_Reg qsocket_funcs[] =
{
	{"udp", udp},
	{"tcp", tcp},
	{NULL, NULL}
};

int
luaopen_qsocket(lua_State *L)
{
	luaL_newlib(L, qsocket_funcs);
	return 1;
}
