// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: LGPL-2.1-or-later

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

	fprintf(stderr, "fmc-fdelay-board-time: a tool for manipulating the FMC Fine Delay time base.\n");
	fprintf(stderr, "Use: \"%s [-V] [-d <dev>] <command>\"\n",
		name);
	fprintf(stderr, "   where the <command> can be:\n"
			"     get                    - shows current time and White Rabbit status.\n"
			"     local                  - sets the time source to the card's local oscillator.\n"
			"     wr                     - sets the time source to White Rabbit.\n"
			"     host                   - sets the time source to local oscillator and coarsely\n"
			"                              synchronizes the card to the system clock.\n"
			"     seconds:[nanoseconds]: - sets local time to the given value.\n"
		        "  and <dev> is the device ID (hexadecimal)\n");
		exit(1);
}

int main(int argc, char **argv)
{
	struct fdelay_board *b;
	struct fdelay_time t;
	int i, get = 0, host = 0, wr_on = 0, wr_off = 0;
	int dev = -1, err;
	char *s;


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

	tools_getopt_d_i(argc, argv, &dev);

	if (dev < 0) {
		fprintf(stderr, "%s: several boards, please pass -d\n",
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

	b = fdelay_open(dev);
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

		err = fdelay_check_wr_mode(b);
		printf("WR Status: ");
		switch(err)
		{
			case ENODEV: 	printf("disabled.\n"); break;
			case ENOLINK: 	printf("link down.\n"); break;
			case EAGAIN: 	printf("synchronization in progress.\n"); break;
			case 0: 	printf("synchronized.\n"); break;
			default:   	printf("error: %s\n", strerror(errno)); break;
		}
		printf("Time: %lli.%09li\n", (long long)t.utc, (long)t.coarse * 8);

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

		err = fdelay_wr_mode(b, 1);

		if(err == ENOTSUP)
		{
			fprintf(stderr, "%s: no support for White Rabbit (check the gateware).\n",
				argv[0]);
			exit(1);
		} else if (err) {
			fprintf(stderr, "%s: fdelay_wr_mode(): %s\n",
				argv[0], strerror(errno));
			exit(1);
		}

		while ((err = fdelay_check_wr_mode(b)) != 0) {
			if( err == ENOLINK )
			{
				fprintf(stderr, "%s: no White Rabbit link (check the cable and the switch).\n",
					argv[0]);
				exit(1);
			}
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
		fprintf(stderr, "%s: fdelay_set_time(): %s\n",
			argv[0], strerror(errno));
		exit(1);
	}
	fdelay_close(b);
	fdelay_exit();
	return 0;
}
