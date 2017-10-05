#include <errno.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/utsname.h>
#include <limits.h>
#include <time.h>
#include <locale.h>
#include <mntent.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <linux/if_link.h>
#include <sys/sysinfo.h>
#include <utmpx.h>

#include <assert.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "auxlib.h"

#ifndef _UTSNAME_LENGTH
#define _UTSNAME_LENGTH 65
#define _UTSNAME_DOMAIN_LENGTH 65
#endif

/*
Uptime via sysinfo(2).
@function uptime
@return uptime (NUMBER)
*/
static int
Fuptime(lua_State *L)
{
	struct sysinfo info = {0};
	errno = 0;
	if (0 > sysinfo(&info)) return luaX_pusherror(L, "sysinfo(2) error");
	lua_createtable(L, 0, 5);
	lua_pushinteger(L, info.uptime);
	lua_setfield(L, -2, "totalseconds");
	info.uptime /= 60;
	lua_pushinteger(L, info.uptime);
	lua_setfield(L, -2, "totalminutes");
	lua_pushinteger(L, info.uptime%60);
	lua_setfield(L, -2, "minutes");
	info.uptime /= 60;
	lua_pushinteger(L, info.uptime%24);
	lua_setfield(L, -2, "hours");
	lua_pushinteger(L, info.uptime/24);
	lua_setfield(L, -2, "days");
	return 1;
}

/*
Load averages via sysinfo(2)
@function loads
@return load averages (TABLE)
*/
static int
Floads(lua_State *L)
{
	int l;
	struct sysinfo info = {0};
	errno = 0;
	if (0 > sysinfo(&info)) return luaX_pusherror(L, "sysinfo(2) error");
	lua_createtable(L, 3, 0);
	for (l = 0; l < 3; l++) {
		lua_pushnumber(L, info.loads[l]/65536.00);
		lua_rawseti(L, -2, l+1);
	}
	return 1;
}

/*
Memory usage via sysinfo(2)
@function mem
@return memory usage (TABLE)
*/
static int
Fmem(lua_State *L)
{
	struct sysinfo info = {0};
	errno = 0;
	if (0 > sysinfo(&info)) return luaX_pusherror(L, "sysinfo(2) error");
	lua_createtable(L, 0, 9);
	lua_pushinteger(L, info.mem_unit);
	lua_setfield(L, -2, "mem_unit");
	lua_pushinteger(L, info.freehigh);
	lua_setfield(L, -2, "freehigh");
	lua_pushinteger(L, info.totalhigh);
	lua_setfield(L, -2, "totalhigh");
	lua_pushinteger(L, info.freeswap);
	lua_setfield(L, -2, "freeswap");
	lua_pushinteger(L, info.totalswap);
	lua_setfield(L, -2, "totalswap");
	lua_pushinteger(L, info.bufferram);
	lua_setfield(L, -2, "bufferram");
	lua_pushinteger(L, info.sharedram);
	lua_setfield(L, -2, "sharedram");
	lua_pushinteger(L, info.freeram);
	lua_setfield(L, -2, "freeram");
	lua_pushinteger(L, info.totalram);
	lua_setfield(L, -2, "totalram");
	return 1;
}

/*
Number of processes via sysinfo(2)
@function procs
@return number of processes (NUMBER)
*/
static int
Fprocs(lua_State *L)
{
	struct sysinfo info = {0};
	errno = 0;
	if (0 > sysinfo(&info)) return luaX_pusherror(L, "sysinfo(2) error");
	lua_pushinteger(L, info.procs);
	return 1;
}

/*
Show sysconf(3) information
@function sysconf
@return values (TABLE)
*/
static int
Fsysconf(lua_State *L)
{
	struct {
		char *name;
		long sc;
	} m[] = {
		{"openmax", sysconf(_SC_OPEN_MAX)},
		{"procs", sysconf(_SC_NPROCESSORS_CONF)},
		{"procsonline", sysconf(_SC_NPROCESSORS_ONLN)},
		{"pagesize", sysconf(_SC_PAGESIZE)},
		{"physpages", sysconf(_SC_PHYS_PAGES)},
		{"avphyspages", sysconf(_SC_AVPHYS_PAGES)}
	};
	size_t c;
	lua_createtable(L, 0, 6);
	for (c = 0; c < sizeof(m)/sizeof(*m); c++) {
		lua_pushinteger(L, m[c].sc);
		lua_setfield(L, -2, m[c].name);
	}
	assert(c == 6);
	return 1;
}

/*
Hostname via gethostname(2)
@function hostname
@return hostname (STRING)
*/
static int
Fhostname(lua_State *L)
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

/*
Show uname information via uname(2)
@function uname
@return information (TABLE)
*/
static int
Funame(lua_State *L)
{
	struct utsname uts = {.nodename = {0}};
	char buf[_UTSNAME_LENGTH] = {0};
	char dbuf[_UTSNAME_DOMAIN_LENGTH] = {0};
	errno = 0;
	if (0 > uname(&uts)) return luaX_pusherror(L, "uname(2) error");
	lua_createtable(L, 0, 6);
	auxL_strnmove(buf, uts.sysname, _UTSNAME_LENGTH);
	lua_pushstring(L, buf);
	lua_setfield(L, -2, "sysname");
	auxL_strnmove(buf, uts.nodename, _UTSNAME_LENGTH);
	lua_pushstring(L, buf);
	lua_setfield(L, -2, "nodename");
	auxL_strnmove(buf, uts.release, _UTSNAME_LENGTH);
	lua_pushstring(L, buf);
	lua_setfield(L, -2, "release");
	auxL_strnmove(buf, uts.version, _UTSNAME_LENGTH);
	lua_pushstring(L, buf);
	lua_setfield(L, -2, "version");
	auxL_strnmove(buf, uts.machine, _UTSNAME_LENGTH);
	lua_pushstring(L, buf);
	lua_setfield(L, -2, "machine");
#ifdef _GNU_SOURCE
	auxL_strnmove(dbuf, uts.domainname, _UTSNAME_DOMAIN_LENGTH);
#else
	auxL_strnmove(dbuf, uts.__domainname, _UTSNAME_DOMAIN_LENGTH);
#endif
	lua_pushstring(L, dbuf);
	lua_setfield(L, -2, "domainname");
	return 1;
}

/*
Hostid via gethostid(3)
@function hostid
@return hostid (STRING)
*/
static int
Fhostid(lua_State *L)
{
	char hostid[9] = {0};
	errno = 0;
	if (0 > snprintf(hostid, sizeof(hostid), "%08lx", gethostid())) return luaX_pusherror(L, "snprintf(3) error.");
	lua_pushstring(L, hostid);
	return 1;
}

/*
Current timezone via strftime(3)
@function timezone
@return timezone (STRING)
*/
static int
Ftimezone(lua_State *L)
{
	char tzbuf[4];
	struct tm *te = {0};
	time_t t;
	t = time(NULL);
	te = localtime(&t);
	setlocale(LC_TIME, "C");
	if (!strftime(tzbuf, sizeof tzbuf, "%Z", te)) return luaX_pusherror(L, "strftime(3) error");
	assert(tzbuf[3] == '\0');
	lua_pushstring(L, tzbuf);
	return 1;
}

/*
Mount information via getmntent(3)
@function mount
@return mount information (TABLE)
*/
static int
Fmount(lua_State *L)
{
	int c = 0;
	struct mntent *m = {0};
	FILE *mtab = setmntent("/etc/mtab", "r");
	if (!mtab) {
		mtab = setmntent("/proc/self/mounts", "r");
	}
	if (!mtab) return luaX_pusherror(L, "setmntent(3) error");
	if (setvbuf(mtab, (void *)0, _IONBF, 0)) return luaX_pusherror(L, "setvbuf(3) error");
	lua_newtable(L);
	while ((m = getmntent(mtab))) {
		lua_createtable(L, 0, 6);
		lua_pushfstring(L, "%s", m->mnt_fsname);
		lua_setfield(L, -2, "fsname");
		lua_pushfstring(L, "%s", m->mnt_dir);
		lua_setfield(L, -2, "dir");
		lua_pushfstring(L, "%s", m->mnt_type);
		lua_setfield(L, -2, "type");
		lua_pushfstring(L, "%s", m->mnt_opts);
		lua_setfield(L, -2, "opts");
		lua_pushinteger(L, m->mnt_freq);
		lua_setfield(L, -2, "freq");
		lua_pushinteger(L, m->mnt_passno);
		lua_setfield(L, -2, "passno");
		lua_rawseti(L, -2, c+1);
		c++;
	}
	endmntent(mtab);
	return 1;
}

/*
Deduce outgoing IPv4 and IPv6 address
@function ipaddress
@return addresses (TABLE)
*/
static int
Fipaddress(lua_State *L)
{
	int fd4, fd6, c;
	char ipv6[INET6_ADDRSTRLEN];
	char ipv4[INET_ADDRSTRLEN];
	struct sockaddr_in r4 = {0}, ip4 = {0};
	struct sockaddr_in6 r6 = {0}, ip6 = {0};
	socklen_t ip4len = sizeof(ip4);
	socklen_t ip6len = sizeof(ip6);

	r4.sin_family = AF_INET;
	r4.sin_port = htons(40444);
	inet_pton(AF_INET, "8.8.8.8", &r4.sin_addr.s_addr);

	r6.sin6_family = AF_INET6;
	r6.sin6_port = htons(40666);
	inet_pton(AF_INET6, "2001:4860:4860::8888", &r6.sin6_addr);

	lua_createtable(L, 0, 2);
	errno = 0;
	fd4 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (0 > fd4) return luaX_pusherror(L, "socket(2) error");
	for (c = 0; c <= 3; c++) {
		if (!connect(fd4, (struct sockaddr *)&r4, sizeof r4)) break;
		if (c == 3) {
			inet_pton(AF_INET, "127.0.0.1", &r4.sin_addr.s_addr);
			if (0 > connect(fd4, (struct sockaddr *)&r4, sizeof r4)) return luaX_pusherror(L, "connect(2) error");
		}
	}
	errno = 0;
	if (0 > getsockname(fd4, (struct sockaddr *)&ip4, &ip4len)) return luaX_pusherror(L, "getsockname(2) error");
	shutdown(fd4, 2);
	close(fd4);
	inet_ntop(AF_INET, &ip4.sin_addr, ipv4, INET_ADDRSTRLEN);
	lua_pushstring(L, ipv4);
	lua_setfield(L, -2, "ipv4");
	errno = 0;
	if (0 > (fd6 = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP))) return luaX_pusherror(L, "socket(2) error");
	for (c = 0; c <= 3; c++) {
		if (!connect(fd6, (struct sockaddr *)&r6, sizeof r6)) break;
		if (c == 3) {
			inet_pton(AF_INET6, "::1", &r6.sin6_addr);
			if (connect(fd6, (struct sockaddr *)&r6, sizeof r6) == -1) {
				shutdown(fd6, 2);
				close(fd6);
				lua_pushstring(L, "disabled");
				lua_setfield(L, -2, "ipv6");
				return 1;
			}
		}
	}
	errno = 0;
	if (0 > getsockname(fd6, (struct sockaddr *)&ip6, &ip6len)) return luaX_pusherror(L, "getsockname(2) error");
	shutdown(fd6, 2);
	close(fd6);
	inet_ntop(AF_INET6, &ip6.sin6_addr, ipv6, INET6_ADDRSTRLEN);
	lua_pushstring(L, ipv6);
	lua_setfield(L, -2, "ipv6");
	return 1;
}

/*
Network interface statistics
@function ifstats
@return stats (TABLE)
*/
static int
ifstats(lua_State *L, struct ifaddrs *i)
{
	struct rtnl_link_stats *stats = i->ifa_data;
	lua_createtable(L, 0, 10);
	lua_pushinteger(L, stats->rx_packets);
	lua_setfield(L, -2, "rx_packets");
	lua_pushinteger(L, stats->tx_packets);
	lua_setfield(L, -2, "tx_packets");
	lua_pushinteger(L, stats->rx_bytes);
	lua_setfield(L, -2, "rx_bytes");
	lua_pushinteger(L, stats->tx_bytes);
	lua_setfield(L, -2, "tx_bytes");
	lua_pushinteger(L, stats->rx_errors);
	lua_setfield(L, -2, "rx_errors");
	lua_pushinteger(L, stats->tx_errors);
	lua_setfield(L, -2, "tx_errors");
	lua_pushinteger(L, stats->rx_dropped);
	lua_setfield(L, -2, "rx_dropped");
	lua_pushinteger(L, stats->tx_dropped);
	lua_setfield(L, -2, "tx_dropped");
	lua_pushinteger(L, stats->multicast);
	lua_setfield(L, -2, "multicast");
	lua_pushinteger(L, stats->collisions);
	lua_setfield(L, -2, "collisions");
	lua_setfield(L, -2, "data");
	return 1;
}

static int
ipaddr(lua_State *L, struct ifaddrs *i)
{
	char ipv4[INET_ADDRSTRLEN];
	char ipv6[INET6_ADDRSTRLEN];
	void *ip = 0;
	if (i->ifa_addr->sa_family == AF_INET) {
		ip = &((struct sockaddr_in *)i->ifa_addr)->sin_addr;
		inet_ntop(AF_INET, ip, ipv4, INET_ADDRSTRLEN);
		lua_pushstring(L, ipv4);
		lua_setfield(L, -2, "ipv4");
	}
	if (i->ifa_addr->sa_family == AF_INET6) {
		ip = &((struct sockaddr_in6 *)i->ifa_addr)->sin6_addr;
		inet_ntop(AF_INET6, ip, ipv6, INET6_ADDRSTRLEN);
		lua_pushstring(L, ipv6);
		lua_setfield(L, -2, "ipv6");
	}
	return 1;
}

/*
Show configured IP addresses.
@function ifaddrs
@return information (TABLE)
*/
static int
Fifaddrs(lua_State *L)
{
	struct ifaddrs *ifaddr = {0};
	struct ifaddrs *i = {0};
	int c = 1;

	errno = 0;
	if (0 > getifaddrs(&ifaddr)) return luaX_pusherror(L, "getifaddrs(3) error");
	lua_newtable(L);
	for (i = ifaddr; i != 0 ; i = i->ifa_next) {
		if (i->ifa_addr == 0) {
			continue;
		}
		lua_newtable(L);
		lua_pushstring(L, i->ifa_name);
		lua_setfield(L, -2, "interface");
		if (i->ifa_addr->sa_family == AF_INET || i->ifa_addr->sa_family == AF_INET6) {
			ipaddr(L, i);
		}
		if (i->ifa_data && (i->ifa_addr->sa_family == AF_PACKET)) {
			ifstats(L, i);
		}
		lua_rawseti(L, -2, c++);
	}
	freeifaddrs(ifaddr);
	return 1;
}

/*
Show MAC addresses
@function macaddrs
@return addresses (TABLE)
*/
static int
Fmacaddrs(lua_State *L)
{
	char buf[8192];
	char mac[18];
	int fd = 0;
	size_t c = 0;
 	struct ifconf ifc = {0};
	struct ifreq *cifr = {0};
	errno = 0;
	fd = socket(PF_INET, SOCK_DGRAM, 0);
	if (0 > fd) return luaX_pusherror(L, "socket(2) error");
	ifc.ifc_len = sizeof buf;
	ifc.ifc_buf = buf;
	errno = 0;
	if (0 > ioctl(fd, SIOCGIFCONF, &ifc)) return luaX_pusherror(L, "ioctl(2) error");
	lua_newtable(L);
	for (c = 0; c < (ifc.ifc_len/sizeof(struct ifreq)); c++) {
		cifr = &ifc.ifc_req[c];
		errno = 0;
		if (0 > ioctl(fd, SIOCGIFHWADDR, cifr)) return luaX_pusherror(L, "ioctl(2) error");
		snprintf(mac, sizeof mac, "%02x:%02x:%02x:%02x:%02x:%02x",
			(unsigned char)cifr->ifr_hwaddr.sa_data[0],
			(unsigned char)cifr->ifr_hwaddr.sa_data[1],
			(unsigned char)cifr->ifr_hwaddr.sa_data[2],
			(unsigned char)cifr->ifr_hwaddr.sa_data[3],
			(unsigned char)cifr->ifr_hwaddr.sa_data[4],
			(unsigned char)cifr->ifr_hwaddr.sa_data[5]);
		assert(mac[17] == '\0');
		lua_pushstring(L, mac);
		lua_setfield(L, -2, cifr->ifr_name);
	}
	return 1;
}

/*
Show utmp information via getutxent(3)
@function utmp
@return information (TABLE)
*/
static int
Futmp(lua_State *L)
{
	struct utmpx *utx = {0};
	setutxent();
	lua_createtable(L, 0, 7);
	while ((utx = getutxent())) {
		lua_pushstring(L, utx->ut_user);
		lua_setfield(L, -2, "user");
		lua_pushstring(L, utx->ut_line);
		lua_setfield(L, -2, "tty");
		lua_pushstring(L, utx->ut_host);
		lua_setfield(L, -2, "hostname");
		lua_pushnumber(L, (float)utx->ut_tv.tv_sec);
		lua_setfield(L, -2, "timestamp");
		lua_pushboolean(L, utx->ut_type & USER_PROCESS);
		lua_setfield(L, -2, "user_process");
		lua_pushboolean(L, utx->ut_type & INIT_PROCESS);
		lua_setfield(L, -2, "init_process");
		lua_pushboolean(L, utx->ut_type & LOGIN_PROCESS);
		lua_setfield(L, -2, "login_process");
	}
	endutxent();
	return 1;
}

static const
luaL_Reg F[] =
{
	{"uptime", Fuptime},
	{"loads", Floads},
	{"mem", Fmem},
	{"procs", Fprocs},
	{"sysconf", Fsysconf},
	{"hostname", Fhostname},
	{"uname", Funame},
	{"hostid", Fhostid},
	{"timezone", Ftimezone},
	{"mount", Fmount},
	{"ipaddress", Fipaddress},
	{"ifaddrs", Fifaddrs},
	{"utmp", Futmp},
	{"macaddrs", Fmacaddrs},
	{NULL, NULL}
};

int
luaopen_factidC(lua_State *L)
{
	luaL_newlib(L, F);
	return 1;
}

