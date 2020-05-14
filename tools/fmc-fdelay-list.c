/* Silly thing that lists installed fine-delay boards */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <glob.h>

#include "fdelay-lib.h"
#include "tools-common.h"

char git_version[] = "git version: " GIT_VERSION;

void help(char *name)
{
	fprintf(stderr, "%s: Lists boards\n"
			"    -V  print version\n", name);
	exit(1);
}

int main(int argc, char **argv)
{
	glob_t g;
	int err, i;

	if (tools_need_help(argc, argv))
		help(argv[0]);

	/* print versions if needed */
	print_version(argc, argv);

	if (argc > 1) {
		fprintf(stderr, "%s: too many arguments (none expected)\n",
			argv[0]);
		exit(1);
	}

	err = fdelay_init();
	if (err) {
		fprintf(stderr, "%s: library initialization failed\n",
			argv[0]);
		exit(1);
	}

	err = glob("/dev/zio/fd-[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9]-0-0-ctrl",
		   GLOB_NOSORT, NULL, &g);
	if (err == GLOB_NOMATCH)
		goto out_glob;

	for (i = 0; i < g.gl_pathc; i++) {
		uint32_t dev_id;
		char dev_id_str[7]= "0x";

		/* Keep only the ID */
		strncpy(dev_id_str + 2,
			g.gl_pathv[i] + strlen("/dev/zio/fd-"), 4);
		dev_id = strtol(dev_id_str, NULL, 0);
		printf("  Fine-Delay Device ID %04x\n", dev_id);
	}

	globfree(&g);

out_glob:
	fdelay_exit();
	return 0;
}
