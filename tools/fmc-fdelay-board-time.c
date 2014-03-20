#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "fdelay-lib.h"

#include "tools-common.h"

static void help(char *name)
{
	fprintf(stderr, "%s: Use \"%s [-i <index>] [-d <dev>] <cmd>\"\n",
		name, name);
	fprintf(stderr, "   cmd is one of \"get\", \"host\", "
		"\"local\", \"wr\" or a floating point time in secs\n");
		exit(1);
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	struct fdelay_time t;
	int nboards, i, get = 0, host = 0, wr_on = 0, wr_off = 0;
	int index = -1, dev = -1;
	char *s;


	/* Standard part of the file (repeated code) */
	if (tools_need_help(argc, argv))
		help(argv[0]);

	nboards = fdelay_init();

	if (nboards < 0) {
		fprintf(stderr, "%s: fdelay_init(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}
	if (nboards == 0) {
		fprintf(stderr, "%s: no boards found\n", argv[0]);
		exit(1);
	}
	if (nboards == 1)
		index = 0; /* so it works with no arguments */

	tools_getopt_d_i(argc, argv, &dev, &index);

	if (index < 0 && dev < 0) {
		fprintf(stderr, "%s: several boards, please pass -i or -d\n",
			argv[0]);
		exit(1);
	}

	/* Parse the mandatory extra argument */
	if (optind != argc - 1)
		help(argv[0]);
	s = argv[optind];
	/* Crappy parser */
	if (!strcmp(s, "get"))
		get = 1;
	else if (!strcmp(s, "host"))
		host = 1;
	else if (!strcmp(s, "wr"))
		wr_on = 1;
	else if (!strcmp(s, "local"))
		wr_off = 1;
	else {
		double nano;
		long long sec;

		memset(&t, 0, sizeof(t));
		i = sscanf(s, "%lli%lf\n", &sec, &nano);
		if (i < 1) {
			fprintf(stderr, "%s: Not a number \"%s\"\n",
				argv[0], s);
			exit(1);
		}
		t.utc = sec;
		t.coarse = nano * 1000 * 1000 * 1000 / 8;
	}

	b = fdelay_open(index, dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	if (get) {
		if (fdelay_get_time(b, &t) < 0) {
			fprintf(stderr, "%s: fdelay_get_time(): %s\n", argv[0],
				strerror(errno));
			exit(1);
		}
		printf("%lli.%09li\n", (long long)t.utc, (long)t.coarse * 8);
		fdelay_close(b);
		fdelay_exit();
		return 0;
	}

	if (host) {
		if (fdelay_set_host_time(b) < 0) {
			fprintf(stderr, "%s: fdelay_set_host_time(): %s\n",
				argv[0], strerror(errno));
			exit(1);
		}
		fdelay_close(b);
		fdelay_exit();
		return 0;
	}

	if (wr_on) {
		setbuf(stdout, NULL);
		printf("Locking the card to WR: ");

		if (fdelay_wr_mode(b, 1) < 0) {
			fprintf(stderr, "%s: fdelay_wr_mode(): %s\n",
				argv[0], strerror(errno));
			exit(1);
		}

		while (fdelay_check_wr_mode(b) != 0) {
			printf(".");
			sleep(1);
		}

		printf(" locked!\n");
		fdelay_close(b);
		fdelay_exit();
		return 0;
	}

	if (wr_off) {
		if (fdelay_wr_mode(b, 0) < 0) {
			fprintf(stderr, "%s: fdelay_wr_mode(): %s\n",
				argv[0], strerror(errno));
			exit(1);
		}

		fdelay_close(b);
		fdelay_exit();
		return 0;
	}

	if (fdelay_set_time(b, &t) < 0) {
		fprintf(stderr, "%s: fdelay_set_host_time(): %s\n",
			argv[0], strerror(errno));
		exit(1);
	}
	fdelay_close(b);
	fdelay_exit();
	return 0;
}
