
/* Simple code that is repeated over several tools */

static inline void tools_getopt_d_i(int argc, char **argv,
				    int *dev, int *index)
{
	char *rest;
	int opt;

	while ((opt = getopt(argc, argv, "d:i:")) != -1) {
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
		}
	}
}
