#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdbool.h>

#include "fdelay-lib.h"

#include "tools-common.h"

char git_version[] = "git version: " GIT_VERSION;

void help(char *name)
{

	fprintf(stderr, "fmc-fdelay-status: reports channel programming\n");
	fprintf(stderr, "Use: \"%s [-V] [-d <dev>] [-r]\"\n", name);
	fprintf(stderr, "   -d <dev>: device ID (hexadecimal)\n");
	fprintf(stderr, "   -r      : display raw hardware configuration\n");
	exit(1);
}

void print_intput_raw(int flags)
{
	fprintf(stdout, "Input, flags 0x%x\n", flags);
}

void print_intput_human(int flags)
{
	bool disabled = flags & FD_TDCF_DISABLE_INPUT;

	fprintf(stdout, "Input    : %s\n",
		disabled ? "disabled" : "enabled");
	if (!disabled) {
		disabled = flags & FD_TDCF_DISABLE_TSTAMP;
		fprintf(stdout, "  timestamping:              %s\n",
			disabled ? "disabled" : "enabled");
		disabled = !(flags & FD_TDCF_TERM_50);
		fprintf(stdout, "  50 Ohm termination:        %s\n",
			disabled ? "disabled" : "enabled");
	}
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	struct fdelay_pulse p;
	int ch, err, dev = -1, raw = 0, opt, flags;

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

	while ((opt = getopt(argc, argv, "d:rh")) != -1) {
		char *rest;
		switch (opt) {
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
		fputs("Input    : failed to get status\n", stdout);
	} else {
		if (raw)
			print_intput_raw(flags);
		else
			print_intput_human(flags);
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
