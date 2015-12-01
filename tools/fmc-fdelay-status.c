#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include "fdelay-lib.h"

#include "tools-common.h"

char git_version[] = "git version: " GIT_VERSION;

void help(char *name)
{

	fprintf(stderr, "fmc-fdelay-status: reports channel programming\n");
	fprintf(stderr, "Use: \"%s [-V] [-i <index>] [-d <dev>] [-r]\"\n", name);
	fprintf(stderr, "   -r: display raw hardware configuration");
	exit(1);
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	struct fdelay_pulse p;
	int nboards, ch, index = -1, dev = -1, raw = 0, opt;

	/* Standard part of the file (repeated code) */
	if (tools_need_help(argc, argv))
		help(argv[0]);

	/* print versions if needed */
	print_version(argc, argv);

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


	while ((opt = getopt(argc, argv, "i:d:rh")) != -1) {
		char *rest;
		switch (opt) {
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
		case 'r':
			raw = 1;
			break;
		case 'h':
			help(argv[0]);
			exit(0);
		}
	}

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

	for (ch = 1; ch <= 4; ch++) {
		if (fdelay_get_config_pulse(b, FDELAY_OUTPUT_USER_TO_HW(ch),
					    &p) < 0) {
			fprintf(stderr, "%s: get_config(channel %i): %s\n",
				argv[0], ch, strerror(errno));
		}
		/* pass hw number again, as the function is low-level */
		report_output_config(FDELAY_OUTPUT_USER_TO_HW(ch),
				    &p, raw ? TOOLS_UMODE_RAW : TOOLS_UMODE_USER);
	}
	fdelay_close(b);
	fdelay_exit();
	return 0;
}
