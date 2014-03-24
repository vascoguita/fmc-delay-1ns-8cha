/* Simple demo that acts on the termination of the first board */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <errno.h>
#include "fdelay-lib.h"

#include "tools-common.h"

void help(char *name)
{
	fprintf(stderr, "%s: Use \"%s [-i <index>] [-d <dev>] [on|off]\n",
		name, name);
	exit(1);
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	int nboards, hwval, newval;
	int index = -1, dev = -1;


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

	/* Parse the extra argument, if any */
	newval = -1;
	if (optind == argc - 1) {
		char *s = argv[optind];
		if (!strcmp(s, "0") || !strcmp(s, "off"))
		    newval = 0;
		else if (!strcmp(s, "1") || !strcmp(s, "on"))
			newval = 1;
		else
			help(argv[0]);
	}
	/* Finally work */
	b = fdelay_open(index, dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	hwval = fdelay_get_config_tdc(b);
	int err = 0;

	switch(newval) {
	case 1:
		hwval |= FD_TDCF_TERM_50;
		err = fdelay_set_config_tdc(b, hwval);
		break;
	case 0:
		hwval &= ~FD_TDCF_TERM_50;
		err = fdelay_set_config_tdc(b, hwval);
		break;
	}
	
	if (err)
	{
		fprintf(stderr, "%s: error setting termination: %s", argv[0], strerror(errno));
		exit(1);
	}

	printf("%s: termination is %s\n", argv[0],
	       hwval & FD_TDCF_TERM_50 ? "on" : "off");

	fdelay_close(b);
	fdelay_exit();
	return 0;
}
