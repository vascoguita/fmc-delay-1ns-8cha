/* Simple demo that acts on the termination of the first board */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <errno.h>
#include "fdelay-lib.h"

#include "tools-common.h"

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	int nboards, hwval, newval;
	int index = -1, dev = -1;


	/* Standard part of the file (repeated code) */
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
	if (optind != argc - 1) {
		fprintf(stderr, "%s: Use \"%s [-i <index>] [-d <dev>] 1|0\n",
			argv[0], argv[0]);
		exit(1);
	}
	newval = -1;
	if (!strcmp(argv[optind], "0"))
		newval = 0;
	else if (!strcmp(argv[optind], "1"))
		newval = 1;
	else {
		fprintf(stderr, "%s: arg \"%s\" is not 0 nor 1\n",
			argv[0], argv[optind]);
		exit(1);
	}

	/* Finally work */
	b = fdelay_open(index, dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	hwval = fdelay_get_config_tdc(b);
	switch(newval) {
	case 1:
		hwval |= FD_TDCF_TERM_50;
		break;
	case 0:
		hwval &= ~FD_TDCF_TERM_50;
		break;
	}
	fdelay_set_config_tdc(b, hwval);
	hwval = fdelay_get_config_tdc(b);
	printf("%s: termination is %d %s\n", argv[0], hwval,
	       hwval & FD_TDCF_TERM_50 ? "on" : "off");

	fdelay_close(b);
	fdelay_exit();
	return 0;
}
