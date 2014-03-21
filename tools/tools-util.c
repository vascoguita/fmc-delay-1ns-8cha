#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include "fdelay-lib.h"
#include "tools-common.h"

extern void help(char *name); /* This is mandatory in all tools */

void tools_getopt_d_i(int argc, char **argv,
				    int *dev, int *index)
{
	char *rest;
	int opt;

	while ((opt = getopt(argc, argv, "d:i:h")) != -1) {
		switch (opt) {
		case 'i':
			*index = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'd':
			*dev = strtol(optarg, &rest, 0);
			if (rest && *rest) {
				fprintf(stderr, "%s: Not a number \"%s\"\n",
					argv[0], optarg);
				exit(1);
			}
			break;
		case 'h':
			help(argv[0]);
		}
	}
}

int tools_need_help(int argc, char **argv)
{
	if (argc != 2)
		return 0;
	if (!strcmp(argv[1], "--help"))
		return 1;
	return 0;
}

void tools_report_time(char *name, struct fdelay_time *t, int umode)
{
	unsigned long long picoseconds =
		t->coarse * 8000ULL +
		t->frac * 8000ULL / 4096ULL;

	printf("  %s  ", name);
	switch(umode) {
	case TOOLS_UMODE_USER:
		printf ("time %10llu:%03llu,%03llu,%03llu,%03llu ps\n",
			(long long)(t->utc),
			(picoseconds / (1000LL * 1000 * 1000)),
			(picoseconds / (1000LL * 1000) % 1000),
			(picoseconds / (1000LL) % 1000),
			(picoseconds % 1000LL));
		break;
	case TOOLS_UMODE_FLOAT:
		printf ("time %10llu.%012llu\n", (long long)(t->utc),
			picoseconds);
		break;
	case TOOLS_UMODE_RAW:
		printf(" raw   utc %10lli,  coarse %9li,  frac %9li\n",
		       (long long)t->utc, (long)t->coarse, (long)t->frac);
		break;
	}
}

void tools_report_action(int channel, struct fdelay_pulse *p, int umode)
{
	char *mode;
	char s[80];

	if (p->mode == FD_OUT_MODE_DISABLED) mode = "disable";
	else if  (p->mode == FD_OUT_MODE_PULSE) mode = "pulse";
	else if (p->mode == FD_OUT_MODE_DELAY) mode = "delay";
	else if (p->mode == 0x80) mode = "already-triggered";
	else {
		sprintf(s, "%i (0x%04x)", p->mode, p->mode);
		mode = s;
	}

	printf("Channel %i, mode %s, repeat %i %s\n",
	       FDELAY_OUTPUT_HW_TO_USER(channel), mode,
	       p->rep, p->rep == -1 ? "(infinite)" : "");
	tools_report_time("start", &p->start, umode);
	tools_report_time("end  ", &p->end, umode);
	tools_report_time("loop ", &p->loop, umode);
}
