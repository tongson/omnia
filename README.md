Omnia
=====

Another Lua 5.3 build system for standalone executables. My main use case is for ELF platforms and statically linking with [musl libc](http://www.musl-libc.org/).

This was made possible by [luastatic](https://github.com/ers35/luastatic)

Similar projects:<br>
[LuaDist](http://luadist.org/)<br/>
[luabuild](https://github.com/stevedonovan/luabuild)

Requires: Development tools e.g. the package build-essential. Does not require autotools.<br/>
Note: Linux and OS X only. xBSD soon.

#### Getting started

1. Edit the following space delimited variables in the top-level Makefile<br/>
     MAIN: Path to the "main" Lua script<br/>
     APP: Lua modules that is specific to your application<br/>
     APP_DIR: Directories containing Lua modules that is specific to your application</br>
     APP_C: Lua C modules that is specific to your application<br/>
     VENDOR: 3rd party Lua modules<br/>
     VENDOR_DIR: directories containing 3rd party Lua modules<br/>
     VENDOR_C: 3rd party C modules<br/>

The APP, VENDOR split is just for organization. Underneath they are using the same Make routines.

1. Run `make`<br/>
If you want to link statically run `make STATIC=1`<br/>
During developlement or debugging run `make DEBUG=1`

#### Adding plain Lua modules. (NOTE: VENDOR and APP are interchangeable.)

Adding plain Lua modules is trivial. $(NAME) is the name of the module passed to `VENDOR`.

1. Copy the Lua module to `vendor/lua/$(NAME).lua`<br/>
  example: `cp ~/Downloads/dkjson.lua vendor/lua`
1. Add `$(NAME)` to `VENDOR`<br/>
  example: `VENDOR= re dkjson`

For Lua modules that are split into multile files, such as Penlight:

1. Copy the directory of the Lua module to `vendor/lua/$(NAME)`<br/>
  example: `cp -R ~/Download/Penlight-1.3.1/lua/pl vendor/lua`
1. Add `$(NAME)` to `VENDOR_DIR`<br/>
  example: `VENDOR_DIR= pl`

For modules with multiple levels of directories you will have to pass each directory. Example:<br/>
  `VENDOR_DIR= ldoc ldoc/builtin ldoc/html`

Lua does not have facilities to traverse directories and I'd like to avoid shell out functions.

#### Adding C modules

1. Provide a Makefile in `vendor/c/$(NAME)/Makefile`. See existing modules such as luaposix and lpeg for pointers.
1. Add `$(NAME)` to `VENDOR_C`

#### Included projects

Project                                                     | Version         | License
------------------------------------------------------------|-----------------|---------
[Lua](http://www.lua.org)[1]                                | 5.3.3           | MIT
[luastatic](https://github.com/ers35/luastatic)             | 0.0.4           | CC0

#### Available modules (Feel free to open a Github issue if you want help with adding a new Lua module.)

Module                                                          | Version         | License
----------------------------------------------------------------|-----------------|---------
[Luaposix](https://github.com/luaposix/luaposix)[2]             | 33.4.0          | MIT
[Linotify](https://github.com/hoelzro/linotify)                 | 0.4             | MIT
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)                | 1.0.0           | MIT
[lsocket](http://tset.de/lsocket/)[3]                           | 1.4             | MIT
[luafilesystem](https://github.com/keplerproject/luafilesystem) | 1.6.3           | MIT
[md5](http://www.rjek.com/luahash-0.00.tar.bz2)                 | 0.00            | PD

[1] Patched with bug fixes #1,#2,#3 from the Lua bugs [page](http://www.lua.org/bugs.html#5.3.3)<br/>
[2] posix.deprecated and posix.compat removed<br/>
[3] Does not include the async resolver<br/>
