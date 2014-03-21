#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "fdelay-lib.h"

#include "tools-common.h"

void help(char *name)
{

	fprintf(stderr, "fmc-fdelay-status: reports channel programming\n");
	fprintf(stderr, "Use: \"%s [-i <index>] [-d <dev>]\"\n", name);
	exit(1);
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	struct fdelay_pulse p;
	int nboards, ch, index = -1, dev = -1;


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

	/* Error if too many arguments */
	if (optind != argc)
		help(argv[0]);


	b = fdelay_open(index, dev);
	if (!b) {
		fprintf(stderr, "%s: fdelay_open(): %s\n", argv[0],
			strerror(errno));
		exit(1);
	}

	for (ch = 1; ch <= 4; ch++) {
		if (fdelay_get_config_pulse(b, FDELAY_OUTPUT_USER_TO_HW(ch),
					    &p) < 0) {
			fprintf(stderr, "%s: get_config(channel %i): %s\n",
				argv[0], ch, strerror(errno));
		}
		/* pass hw number again, as the function is low-level */
		tools_report_action(FDELAY_OUTPUT_USER_TO_HW(ch), &p);
	}
	fdelay_close(b);
	fdelay_exit();
	return 0;
}
