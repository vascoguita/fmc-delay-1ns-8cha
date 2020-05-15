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

char git_version[] = "git version: " GIT_VERSION;

void help(char *name)
{
	fprintf(stderr, "%s: Use \"%s [-V] [-d <dev>] [<opts>]\n",
		name, name);
	fprintf(stderr, " options:\n"
		"   -c <count>      default is 0 and means forever\n"
		"   -n              nonblocking: only empty buffer\n"
		"   -r              raw mode: show hex timestamps\n"
		"   -f              floating point (default): sec.nsec\n");
	exit(1);
}

void dump_input(struct fdelay_time *t, int np, int umode)
{
	int i;

	for (i = 0; i < np; i++, t++) {
		printf("seq %5i: ", t->seq_id);
		tools_report_time("", t, umode);
	}
}




int main(int argc, char **argv)
{
	struct fdelay_board *b;
	int opt, err, dev = -1;
	int nonblock = 0, count = 0;
	int umode = TOOLS_UMODE_USER, flags;


	/* Standard part of the file (repeated code) */
	if (tools_need_help(argc, argv))
		help(argv[0]);

	/* print versions if needed */
	print_version(argc, argv);

	err = fdelay_init();
	if (err) {
		fprintf(stderr, "%s: library initialization failed\n", argv[0]);
		exit(1);
	}

	/* Parse our specific arguments, starting back from argv[1] */
	while ((opt = getopt(argc, argv, "d:hc:nrf")) != -1) {
		switch (opt) {
			char *rest;
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
			umode = TOOLS_UMODE_RAW;
			break;

		case 'f':
			umode = TOOLS_UMODE_FLOAT;
			break;
		}
	}
	if (optind != argc)
		help(argv[0]); /* too many arguments */

	if (dev < 0) {
		fprintf(stderr, "%s: several boards, please pass -d\n",
			argv[0]);
		exit(1);
	}

	b = fdelay_open(dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	flags = fdelay_get_config_tdc(b);
	if (flags < 0) {
		err = flags;
		goto out;
	}
	flags &= ~(FD_TDCF_DISABLE_INPUT | FD_TDCF_DISABLE_TSTAMP);
	err = fdelay_set_config_tdc(b, flags);
	if (err) {
		fprintf(stderr, "%s: failed to configure TDC: %s\n", argv[0],
				fdelay_strerror(errno));
		goto out;
	}
	/* now read pulses, "np" at a time */
	while (1) {
		struct fdelay_time pdata[16];
		int ret, np = 16;

		if (count && count < np)
			np = count;
		ret = fdelay_read(b, pdata, np, nonblock);
		if (ret < 0) {
			err = ret;
			fprintf(stderr, "%s: fdelay_read: %s\n", argv[0],
				strerror(errno));
			break;
		}
		if (!ret)
			continue;

		dump_input(pdata, ret, umode);

		if (nonblock) /* non blocking: nothing more to do */
			break;

		if (!count) /* no count: forever */
			continue;

		count -= ret;
		if (!count) /* asked that many, we are done */
			break;
	}

out:
	fdelay_close(b);
	fdelay_exit();
	return err;
}
