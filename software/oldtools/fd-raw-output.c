// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <glob.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <linux/zio.h>
#include <linux/zio-user.h>
#include <fine-delay.h>

int main(int argc, char **argv)
{
	glob_t glob_buf;
	struct zio_control ctrl;
	int fdc;
	char *s;
	int i, j, val, ch;
	uint32_t *attrs;

	/* glob to find the device; use the first */
	glob("/dev/fd-*-1-0-ctrl", 0, NULL, &glob_buf);
	glob("/dev/zio/fd-*-1-0-ctrl", GLOB_APPEND, NULL, &glob_buf);
	glob("/dev/zio/zio-fd-*-1-0-ctrl", GLOB_APPEND, NULL, &glob_buf);

	if (glob_buf.gl_pathc != 1) {
		fprintf(stderr, "%s: found %zu devices, need 1 only\n",
			argv[0], glob_buf.gl_pathc);
		exit(1);
	}

	s = glob_buf.gl_pathv[0];
	if (getenv("CHAN")) {
		/* Hack: change the channel */
		ch = atoi(getenv("CHAN"));
		if (ch)
			s[strlen(s)-strlen("1-0-ctrl")] = '0' + ch;
	}

	fdc = open(s, O_WRONLY);
	if (fdc < 0) {
		fprintf(stderr, "%s: %s: %s\n", argv[0], s, strerror(errno));
		exit(1);
	}

	memset(&ctrl, 0, sizeof(ctrl));
	attrs = ctrl.attr_channel.ext_val;

	for (i = 1; i < argc; i++) {
		j = i - 1 + FD_ATTR_DEV__LAST;
		if (sscanf(argv[i], "+%i", &val) == 1) {
			val += time(NULL);
		} else if (sscanf(argv[i], "%i", &val) != 1) {
			fprintf(stderr, "%s: not a number \"%s\"\n", argv[0],
				argv[i]);
			exit(1);
		}
		attrs[j] = val;
	}
	/* we need to fill the nsample field of the control */
	ctrl.attr_trigger.std_val[1] = 1;
	ctrl.nsamples = 1;
	ctrl.ssize = 4;
	ctrl.nbits = 32;

	write(fdc, &ctrl, sizeof(ctrl));
	exit(0);
}
