Omnia -- Batteries included Lua
=====

Compile Lua, Fennel and MoonScript source code into standalone executables. This makes it easy to use Lua/Fennel/Moonscript for system programming and general purpose scripting.

Another Lua 5.3 build system for standalone executables.

This was made possible by [luastatic](https://github.com/ers35/luastatic)

Similar projects:<br>
[LuaDist](http://luadist.org/)<br/>
[luabuild](https://github.com/stevedonovan/luabuild)

Requires: GNU Make, a compiler and binutils (or equivalent). Installing development tools e.g. the package build-essential should have everything you need. Does not require autotools.<br/>
Note: Linux and OS X only. xBSD soon.

#### Getting started

1. Download a release or clone the repo: `git clone --depth 1 https://github.com/tongson/omnia`

2. Edit the following space delimited variables in the top-level Makefile<br/>
     MAIN: The "main" script in the `bin/` directory<br/>
     SRC: Modules that are specific to your application. Copy these to `src/lua`. <br/>
     SRC_DIR: Directories containing modules that are specific to your application. Copy these to `src/lua`.</br>
     SRC_C: C modules that are specific to your application. Copy these to `src/c`.<br/>
     VENDOR: 3rd party modules<br/>
     VENDOR_DIR: directories containing 3rd party modules<br/>
     VENDOR_C: 3rd party C modules<br/>

3. Copy the main source file into the `bin/` directory.

4. Copy modules into `src/lua/` or `vendor/lua/`.

The SRC, VENDOR split is just for organization. Underneath they are using the same Make routines.

Run `make` during development or `make release` for the final executable without debug symbols in `bin/`.<br/>
If you want to link statically run `make release STATIC=1`<br/>

You can also use omnia as a base of the monorepo of your Lua/Fennel/Moonscript code.

#### Adding plain Lua, Fennel and MoonScript modules. (NOTE: VENDOR and SRC are interchangeable.)

Adding plain modules is trivial. $(NAME) is the name of the module passed to `VENDOR`.

1. Copy the module to `vendor/lua/$(NAME).{lua,fnl,moon}`<br/>
  example: `cp ~/Downloads/dkjson.lua vendor/lua`
1. Add `$(NAME)` to `VENDOR`<br/>
  example: `VENDOR= re dkjson`

For modules that are split into multile files, such as Penlight:

1. Copy the directory of the Lua module to `vendor/lua/$(NAME)`<br/>
  example: `cp -R ~/Download/Penlight-1.3.1/lua/pl vendor/lua`
1. Add `$(NAME)` to `VENDOR_DIR`<br/>
  example: `VENDOR_DIR= pl`

For modules with multiple levels of directories you will have to pass each directory. Example:<br/>
  `VENDOR_DIR= ldoc ldoc/builtin ldoc/html`

Lua does not have the facilities to traverse directories and I'd like to avoid shell out functions.

#### Adding C modules

1. Provide a Makefile in `vendor/c/$(NAME)/Makefile`. See existing modules such as luaposix and lpeg for pointers.
1. Add `$(NAME)` to `VENDOR_C`

#### Development

The default make target is development which runs Luacheck against your Lua source code.

Luacov is also integrated. Just run the your test code with Luacov loaded e.g. `bin/lua -lluacov tests.lua`. Then `bin/luacov.lua` to generate the report.

#### Example application using omnia

The included Lua script might be too simplistic to demonstrate Omnia. For a more complicated application check my 'fork' of [LDoc](https://github.com/tongson/LDoc)

#### Fennel and MoonScript support

Just treat Fennel/MoonScript source the same as Lua source. The Make routines will handle the compilation of Fennel/MoonScript sources and link the appropriate compiled Lua source to the final executable.

The MoonScript standard library is included but you have to add `moon` to the `VENDOR` line in the Makefile.

A copy of the MoonScript REPL `moor` is also included. To compile, run `make bin/moor`.
A copy of the upstream Fennel REPL and compiler is also included. To compile, run `make bin/fennel`.

#### Included projects

Project                                                     | Version         | License
------------------------------------------------------------|-----------------|---------
[Lua](http://www.lua.org)                                   | 5.3.4           | MIT
[luastatic](https://github.com/ers35/luastatic)             | 0.0.9-dev       | CC0
[Fennel](https://github.com/bakpakin/Fennel)                | HEAD            | MIT
[MoonScript](http://moonscript.org)                         | 0.5.0           | MIT
[moor](https://github.com/Nymphium/moor)                    | HEAD            | MIT
[linenoise](http://github.com/antirez/linenoise)            | c894b9e         | BSD 2C
[moonpick](https://github.com/nilnor/moonpick)              | HEAD            | MIT
[luacheck](https://github.com/mpeterv/luacheck)             | 0.19.0          | MIT
[luacov](https://github.com/keplerproject/luacov)           | 0.12.0          | MIT

#### Available modules (Feel free to open a Github issue if you want help with adding a new Lua module.)

Module                                                                          | Version         | License
--------------------------------------------------------------------------------|-----------------|---------
[Luaposix](https://github.com/luaposix/luaposix)[1]                             | 34.0            | MIT
[Linotify](https://github.com/hoelzro/linotify)                                 | 0.5             | MIT
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)                                | 1.0.1           | MIT
[lsocket](http://tset.de/lsocket/)[2]                                           | 1.4             | MIT
[luafilesystem](https://github.com/keplerproject/luafilesystem)                 | 1.6.3           | MIT
[lua-linenoise](https://github.com/hoelzro/lua-linenoise)                       | f30fa48         | MIT
[inspect.lua](https://github.com/kikito/inspect.lua)                            | 3.1.0           | MIT
[cimicida](https://github.com/Configi/configi)                                  | HEAD            | MIT
[lib](https://github.com/Configi/configi)                                       | HEAD            | MIT
[u-test](https://github.com/IUdalov/u-test/)                                    | HEAD            | MIT
[px](https://github.com/Configi/configi)                                        | HEAD            | MIT
[factid](https://github.com/Configi/configi)                                    | HEAD            | MIT
[Lua-cURLv3](https://github.com/Lua-cURL/Lua-cURLv3)                            | b4d1d79         | MIT
[plc](https://github.com/philanc/plc)                                           | HEAD            | MIT
[argparse](https://github.com/mpeterv/argparse)                                 | 0.5.0           | MIT
[dkjson](http://dkolf.de/src/dkjson-lua.fsl/home)                               | c23a579         | MIT
[lua-ConciseSerialization](https://github.com/fperrad/lua-ConciseSerialization) | 0.2.0           | MIT
[luaproxy](https://github.com/arcapos/luaproxy)                                 | 6d7bb0c         | BSD 3C
[luatweetnacl](https://github.com/philanc/luatweetnacl)                         | 0.5-1           | MIT
[lua-array](https://github.com/cloudwu/lua-array)                               | 676ba83         | MIT
[lpty](http://tset.de/lpty/index.html)                                          | 1.2.2           | MIT
[uuid](https://github.com/Configi/configi)                                      | HEAD            | Apache
[ftcsv](https://github.com/FourierTransformer/ftcsv)                            | 1.1.6           | MIT
[ustring](https://github.com/wikimedia/mediawiki-extensions-Scribunto)          | 961405f         | MIT

[1] posix.deprecated and posix.compat removed<br/>
[2] Does not include the async resolver<br/>
