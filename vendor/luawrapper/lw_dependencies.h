/**
 * @file lw_dependencies.h
 * @brief This header declares the list of dependencies the lua wrapper will
 * load at startup, before running the main script. lw_dependencies.c must be
 * updated to list them all.
 *
 * @date 24 juin 2014
 * @author carrier.nicolas0@gmail.com
 */

#ifndef LW_DEPENDENCIES_H_
#define LW_DEPENDENCIES_H_

#include <lauxlib.h>

/**
 * @var lw_dependencies
 * @brief list of the C lua modules which will be loaded at startup
 */
extern const struct luaL_Reg lw_dependencies[];

#endif /* LW_DEPENDENCIES_H_ */
