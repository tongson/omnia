/*
 * Copyright (c) 2004-2005, 2007, 2010
 *	Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <sys/param.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <dirent.h>
#define NAMLEN(dirent) strlen((dirent)->d_name)

#ifndef HAVE_FCNTL_CLOSEM
void
closefrom(int lowfd)
{
	struct dirent *dent;
	DIR *dirp;
	char *endp;
	long fd;

	/* Use /proc/self/fd directory if it exists. */
	dirp = opendir("/proc/self/fd");
	if (dirp != NULL) {
		while ((dent = readdir(dirp)) != NULL) {
			fd = strtol(dent->d_name, &endp, 10);
			if (dent->d_name != endp && *endp == '\0' &&
			    fd >= 0 && fd < INT_MAX && fd >= lowfd &&
			    fd != dirfd(dirp))
				(void)close((int)fd);
		}
		(void)closedir(dirp);
	}
}

#else
void
closefrom(int lowfd)
{
	fcntl(lowfd, F_CLOSEM, 0)
}

#endif
