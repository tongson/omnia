// Copyright (c) 2017  Phil Leblanc  -- see LICENSE file
// ---------------------------------------------------------------------
/*   luatweetnacl

A binding to the wonderful NaCl crypto library by Dan Bernstein,
Tanja Lange et al. -- http://nacl.cr.yp.to/

The version included here is the "Tweet" version ("NaCl in 100 tweets")
by Dan Bernstein et al. --  http://tweetnacl.cr.yp.to/index.html


170805 
- replaced malloc()/free() buffer allocation with lua_newuserdata()
  to prevent memory leaks in case of out-of-memory errors in 
  lua_pushlstring() calls. (as suggested by Daurnimator)
  
160827
- the leading 32 and 16 null bytes are no longer required or 
  returned to the user. This is processed in the Lua binding
  functions. 

160408 
- removed the ill-designed, "convenience" functions

150721
- split luazen and tweetnacl. removed luazen history. 
- nacl lua interface is in this file (luatweetnacl.c)

150630
loaded TweetNaCl version 20140427 from
http://tweetnacl.cr.yp.to/index.html
it includes: tweetnacl.c, tweetnacl.h
added luatweetnacl.c for the Lua binding

randombytes()  not included in the original tweetnacl. 
got randombytes.c from Tanja Lange site
https://hyperelliptic.org/nacl/nacl-20110221.tar.bz2

NaCl specs: see http://nacl.cr.yp.to/

*/

#define LUATWEETNACL_VERSION "luatweetnacl-0.5"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "tweetnacl.h"


//=========================================================
// compatibility with Lua 5.2  --and lua 5.3, added 150621
// (from roberto's lpeg 0.10.1 dated 101203)
//
#if (LUA_VERSION_NUM >= 502)

#undef lua_equal
#define lua_equal(L,idx1,idx2)  lua_compare(L,(idx1),(idx2),LUA_OPEQ)

#undef lua_getfenv
#define lua_getfenv	lua_getuservalue
#undef lua_setfenv
#define lua_setfenv	lua_setuservalue

#undef lua_objlen
#define lua_objlen	lua_rawlen

#undef luaL_register
#define luaL_register(L,n,f) \
	{ if ((n) == NULL) luaL_setfuncs(L,f,0); else luaL_newlib(L,f); }

#endif
//=========================================================

# define LERR(msg) return luaL_error(L, msg)

typedef unsigned char u8;
typedef unsigned long u32;
typedef unsigned long long u64;

//------------------------------------------------------------
// nacl functions (the "tweetnacl version")

extern int randombytes(unsigned char *x,unsigned long long xlen); 


static int tw_randombytes(lua_State *L) {
	// Lua API:   randombytes(n)  returns a string with n random bytes 
	// n must be 256 or less.
	// randombytes return nil, error msg  if the RNG fails or if n > 256
	//	
    size_t bufln; 
	unsigned char buf[256];
	lua_Integer li = luaL_checkinteger(L, 1);  // 1st arg
	if ((li > 256 ) || (li < 0)) {
		lua_pushnil (L);
		lua_pushliteral(L, "invalid byte number");
		return 2;      		
	}
	int r = randombytes(buf, li);
	if (r != 0) { 
		lua_pushnil (L);
		lua_pushliteral(L, "random generator error");
		return 2;         
	} 	
    lua_pushlstring (L, buf, li); 
	return 1;
} //randombytes()

static int tw_box_keypair(lua_State *L) {
	// generate and return a random key pair (pk, sk)
	unsigned char pk[crypto_box_PUBLICKEYBYTES];
	unsigned char sk[crypto_box_SECRETKEYBYTES];
	int r = crypto_box_keypair(pk, sk);
	lua_pushlstring (L, pk, crypto_box_PUBLICKEYBYTES); 
	lua_pushlstring (L, sk, crypto_box_SECRETKEYBYTES); 
	return 2;
}//box_keypair()

static int tw_box_getpk(lua_State *L) {
	// return the public key associated to a secret key
	size_t skln;
	unsigned char pk[crypto_box_PUBLICKEYBYTES];
	const char *sk = luaL_checklstring(L,1,&skln); // secret key
	if (skln != crypto_box_SECRETKEYBYTES) LERR("bad sk size");
	int r = crypto_scalarmult_base(pk, sk);
	lua_pushlstring (L, pk, crypto_box_PUBLICKEYBYTES); 
	return 1;
}//box_getpk()

static int tw_box(lua_State *L) {
	size_t mln, nln, pkln, skln;
	const char *m = luaL_checklstring(L,1,&mln);   // plaintext
	const char *n = luaL_checklstring(L,2,&nln);   // nonce
	const char *pk = luaL_checklstring(L,3,&pkln); // public key
	const char *sk = luaL_checklstring(L,4,&skln); // secret key
	if (nln != crypto_box_NONCEBYTES) LERR("box_open: bad nonce size");
	if (pkln != crypto_box_PUBLICKEYBYTES) LERR("box_open: bad pk size");
	if (skln != crypto_box_SECRETKEYBYTES) LERR("box_open: bad sk size");
	unsigned char * buf = lua_newuserdata(L, mln+64);
	// will encrypt over the plain text with a 64 byte window
	memcpy(buf+64, m, mln);
	// zero the 32 bytes before the plain text m
	memset(buf+64-32, 0, 32);
	int r = crypto_box(buf, buf+64-32, mln+32, n, pk, sk);
	lua_pushlstring(L, buf+16, mln+16); 
	return 1;   
}// box()

static int tw_box_open(lua_State *L) {
	char * msg = "box_open: argument error";
	size_t cln, nln, pkln, skln;
	const char *c = luaL_checklstring(L,1,&cln);	
	const char *n = luaL_checklstring(L,2,&nln);	
	const char *pk = luaL_checklstring(L,3,&pkln);	
	const char *sk = luaL_checklstring(L,4,&skln);	
	if (nln != crypto_box_NONCEBYTES) LERR("box_open: bad nonce size");
	if (pkln != crypto_box_PUBLICKEYBYTES) LERR("box_open: bad pk size");
	if (skln != crypto_box_SECRETKEYBYTES) LERR("box_open: bad sk size");
	unsigned char * buf = lua_newuserdata(L, cln+64);
	// will decrypt over the encrypted text with a 64 byte window
	memcpy(buf+64, c, cln);
	// zero the 16 bytes before the encr text
	memset(buf+64-16, 0, 16);
	//~ int r = crypto_box_open(buf, c, cln, n, pk, sk);
	int r = crypto_box_open(buf, buf+64-16, cln+16, n, pk, sk);
	if (r != 0) { 
		lua_pushnil (L);
		lua_pushfstring(L, "box_open error %d", r);
		return 2;         
	} 
	// return the plain text, after the 32 null
	// plain text is 16 bytes shorter than encrypted (the poly1305 MAC)
	lua_pushlstring (L, buf+32, cln-16); 
	return 1;
} // box_open()

static int tw_box_beforenm(lua_State *L) {
	int r;
	size_t pkln, skln;
	u8 k[32];
	const char *pk = luaL_checklstring(L,1,&pkln); // dest public key
	const char *sk = luaL_checklstring(L,2,&skln); // src secret key
	if (pkln != crypto_box_PUBLICKEYBYTES) LERR("box_beforenm: bad pk size");
	if (skln != crypto_box_SECRETKEYBYTES) LERR("box_beforenm: bad sk size");
	r = crypto_box_beforenm(k, pk, sk);
	lua_pushlstring(L, k, 32); 
	return 1;   
}// box()

static int tw_secretbox(lua_State *L) {
	int r;
	size_t mln, nln, kln;
	const char *m = luaL_checklstring(L,1,&mln);	
	const char *n = luaL_checklstring(L,2,&nln);	
	const char *k = luaL_checklstring(L,3,&kln);	
	if (nln != crypto_box_NONCEBYTES) LERR("secretbox: bad nonce size");
	if (kln != crypto_secretbox_KEYBYTES) LERR("secretbox: bad key size");
	unsigned char * buf = lua_newuserdata(L, mln+64);
	// will encrypt over the plain text with a 64 byte window
	memcpy(buf+64, m, mln);
	// zero the 32 bytes before the plain text m
	memset(buf+64-32, 0, 32);
	//~ r = crypto_secretbox(buf, m, mln, n, k);
	r = crypto_secretbox(buf, buf+64-32, mln+32, n, k);
	// bytes 0-15 are null, 16-31 are the poly1305 MAC
	lua_pushlstring (L, buf+16, mln+16); 
	return 1;
} // secretbox()

static int tw_secretbox_open(lua_State *L) {
	int r = 0;
	size_t cln, nln, kln;
	const char *c = luaL_checklstring(L,1,&cln);	
	const char *n = luaL_checklstring(L,2,&nln);	
	const char *k = luaL_checklstring(L,3,&kln);	
	//~ if (cln <= crypto_box_ZEROBYTES) LERR("secretbox_open: cln <= ZEROBYTES");
	if (nln != crypto_box_NONCEBYTES) LERR("secretbox_open: bad nonce size");
	if (kln != crypto_secretbox_KEYBYTES) LERR("secretbox_open: bad key size");
	unsigned char * buf = lua_newuserdata(L, cln+128);
	memcpy(buf+128, c, cln);
	// zero the 16 bytes before the encr text
	memset(buf+128-16, 0, 16);
	//~ r = crypto_secretbox_open(buf, c, cln, n, k);
	r = crypto_secretbox_open(buf, buf+128-16, cln+16, n, k);
	if (r != 0) { 
		lua_pushnil (L);
		lua_pushfstring(L, "secretbox_open error %d", r);
		return 2;         
	} 
	// the first 32 bytes should be null. ignore them
	// plain is 16 byte shorter than encrypted (the 16-byte MAC)
	lua_pushlstring (L, buf+32, cln-16); 
	return 1;
} // secretbox_open()

static int tw_stream(lua_State *L) {
	// stream(mln, nonce, key)
	// return a stream of mln bytes 
	// (mln can be any length, no >16 or >32 constraint)
	int r;
	size_t mln, nln, kln;
	mln = luaL_checkinteger(L,1);	
	const char *n = luaL_checklstring(L,2,&nln);	
	const char *k = luaL_checklstring(L,3,&kln);	
	if (nln != crypto_box_NONCEBYTES) LERR("bad nonce size");
	if (kln != crypto_secretbox_KEYBYTES) LERR("bad key size");
	unsigned char * buf = lua_newuserdata(L, mln);
	r = crypto_stream(buf, mln, n, k);
	lua_pushlstring (L, buf, mln); 
	return 1;
} // stream()

static int tw_stream_xor(lua_State *L) {
	// stream_xor(m, nonce, key)
	// equivalent to m XOR stream(#m, nonce, key)
	// m can be any length. no >16 or >32 constraint
	int r;
	size_t mln, nln, kln;
	const char *m = luaL_checklstring(L,1,&mln);	
	const char *n = luaL_checklstring(L,2,&nln);	
	const char *k = luaL_checklstring(L,3,&kln);	
	if (nln != crypto_box_NONCEBYTES) LERR("bad nonce size");
	if (kln != crypto_secretbox_KEYBYTES) LERR("bad key size");
	unsigned char * buf = lua_newuserdata(L, mln);
	r = crypto_stream_xor(buf, m, mln, n, k);
	lua_pushlstring (L, buf, mln); 
	return 1;
} // stream_xor()

static int tw_onetimeauth(lua_State *L) {
	// no leading zerobytes
	int r;
	u8 mac[16];
	size_t mln, kln;
	const char *m = luaL_checklstring(L,1,&mln);	
	const char *k = luaL_checklstring(L,2,&kln);	
	if (kln != crypto_secretbox_KEYBYTES) LERR("bad key size");
	r = crypto_onetimeauth(mac, m, mln, k);
    lua_pushlstring (L, mac, 16); 
    return 1;
}//onetimeauth()

// onetimeauth_verify - not implemented, very easy to do in Lua:
//      if onetimeauth(m, k) == mac then ...

static int tw_sha512(lua_State *L) {
    size_t sln; 
    const char *src = luaL_checklstring (L, 1, &sln);
    char digest[64];
	crypto_hash(digest, (const unsigned char *) src, (unsigned long long) sln);  
    lua_pushlstring (L, digest, 64); 
    return 1;
}

//-- sign functions (ed25519)
// sign_BYTES 64
// sign_PUBLICKEYBYTES 32
// sign_SECRETKEYBYTES 64

static int tw_sign_keypair(lua_State *L) {
	// generate and return a random key pair (pk, sk)
	// (the last 32 bytes of sk are pk)
	unsigned char pk[32];
	unsigned char sk[64];
	int r = crypto_sign_keypair(pk, sk);
	lua_pushlstring (L, pk, 32); 
	lua_pushlstring (L, sk, 64); 
	return 2;
}//sign_keypair()


static int tw_sign(lua_State *L) {
	int r;
	size_t mln, skln;
	const char *m = luaL_checklstring(L,1,&mln);   // text to sign
	const char *sk = luaL_checklstring(L,2,&skln); // secret key
	if (skln != 64) LERR("bad signature sk size");
	u64 usmln = mln + 64;
	unsigned char * buf = lua_newuserdata(L, usmln);
	r = crypto_sign(buf, &usmln, m, mln, sk);
	if (r != 0) { 
		lua_pushnil (L);
		lua_pushfstring(L, "sign error %d", r);
		return 2;         
	} 
	lua_pushlstring(L, buf, usmln); 
	return 1;   
}// sign()

static int tw_sign_open(lua_State *L) {
	int r;
	size_t smln, pkln;
	const char *sm = luaL_checklstring(L,1,&smln);   // signed text
	const char *pk = luaL_checklstring(L,2,&pkln);   // public key
	if (pkln != 32) LERR("bad signature pk size");
	unsigned char * buf = lua_newuserdata(L, smln);
	u64 umln;
	r = crypto_sign_open(buf, &umln, sm, smln, pk);
	if (r != 0) { 
		lua_pushnil (L);
		lua_pushfstring(L, "sign_open error %d", r);
		return 2;         
	} 
	lua_pushlstring(L, buf, umln); 
	return 1;   
}// sign_open()




//------------------------------------------------------------
// lua library declaration
//
static const struct luaL_Reg luatweetnacllib[] = {
	// nacl functions
	{"randombytes", tw_randombytes},
	{"box", tw_box},
	{"box_open", tw_box_open},
	{"box_keypair", tw_box_keypair},
	{"box_getpk", tw_box_getpk},
	{"secretbox", tw_secretbox},
	{"secretbox_open", tw_secretbox_open},
	{"box_afternm", tw_secretbox},
	{"box_open_afternm", tw_secretbox_open},
	{"box_beforenm", tw_box_beforenm},
	{"box_stream_key", tw_box_beforenm}, // an alias for box_beforenm()
	{"stream", tw_stream},
	{"stream_xor", tw_stream_xor},
	{"onetimeauth", tw_onetimeauth},
	{"poly1305", tw_onetimeauth}, 
	{"hash", tw_sha512},
	{"sha512", tw_sha512}, 
	{"sign", tw_sign}, 
	{"sign_open", tw_sign_open}, 
	{"sign_keypair", tw_sign_keypair}, 
		
	{NULL, NULL},
};

int luaopen_luatweetnacl (lua_State *L) {
	luaL_register (L, "luatweetnacl", luatweetnacllib);
    // 
    lua_pushliteral (L, "VERSION");
	lua_pushliteral (L, LUATWEETNACL_VERSION); 
	lua_settable (L, -3);
	return 1;
}

