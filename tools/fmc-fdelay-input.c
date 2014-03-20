#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "fdelay-lib.h"

#include "tools-common.h"

static void help(char *name)
{
	fprintf(stderr, "%s: Use \"%s [-i <index>] [-d <dev>] [<opts>]\n",
		name, name);
	fprintf(stderr, " options:\n"
		"   -c <count>      default is 0 and means forever\n"
		"   -n              nonblocking: only empty buffer\n"
		"   -r              raw mode: show hex timestamps\n"
		"   -f              floating point (default): sec.nsec\n");
	exit(1);
}

void dump_input(struct fdelay_time *t, int np, int israw)
{
	int i;

	for (i = 0; i < np; i++, t++) {
		printf("seq %5i: ", t->seq_id);
		if (israw)
			printf("timestamps %016llx %08x %08x\n",
			       (long long)(t->utc), t->coarse, t->frac);
		else
			printf("time %10lli.%09li\n",
			       (long long)(t->utc), (long)t->coarse * 8);
	}
}



int main(int argc, char **argv)
{
	struct fdelay_board *b;
	int nboards;
	int opt, index = -1, dev = -1;
	int nonblock = 0, raw = 0, count = 0;


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

	/* Parse our specific arguments, starting back from argv[1] */
	while ((opt = getopt(argc, argv, "d:i:hc:nrf")) != -1) {
		switch (opt) {
			char *rest;

		case 'i':
			index = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'd':
			dev = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'h':
			help(argv[0]);

		case 'c':
			count = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;

		case 'n':
			nonblock = O_NONBLOCK;
			break;

		case 'r':
			raw = 1;
			break;

		case 'f':
			raw = 0;
			break;
		}
	}
	if (optind != argc)
		help(argv[0]); /* too many arguments */

	if (index < 0 && dev < 0) {
		fprintf(stderr, "%s: several boards, please pass -i or -d\n",
			argv[0]);
		exit(1);
	}

	b = fdelay_open(index, dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	/* now read pulses, "np" at a time */
	while (1) {
		struct fdelay_time pdata[16];
		int ret, np = 16;

		if (count && count < np)
			np = count;
		ret = fdelay_read(b, pdata, np, nonblock);
		if (ret < 0) {
			fprintf(stderr, "%s: fdelay_read: %s\n", argv[0],
				strerror(errno));
			break;
		}
		if (!ret)
			continue;

		dump_input(pdata, ret, raw);

		if (nonblock) /* non blocking: nothing more to do */
			break;

		if (!count) /* no count: forever */
			continue;

		count -= ret;
		if (!count) /* asked that many, we are done */
			break;
	}

	fdelay_close(b);
	fdelay_exit();
	return 0;
}
