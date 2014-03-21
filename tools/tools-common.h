/*
 * Simple code that is repeated over several tools
 */

static void help(char *name); /* This is mandatory in all tools */

static inline void tools_getopt_d_i(int argc, char **argv,
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

static inline int tools_need_help(int argc, char **argv)
{
	if (argc != 2)
		return 0;
	if (!strcmp(argv[1], "--help"))
		return 1;
	return 0;
}

static inline void report_time(char *name, struct fdelay_time *t)
{
	printf("   %s   utc %10lli,  coarse %9li,  frac %9li\n",
	       name, (long long)t->utc, (long)t->coarse, (long)t->frac);
}

static inline void tools_report_action(int channel, struct fdelay_pulse *p)
{
	char *mode;

	if (p->mode == FD_OUT_MODE_DISABLED) mode = "disable";
	else if  (p->mode == FD_OUT_MODE_PULSE) mode = "pulse";
	else if (p->mode == FD_OUT_MODE_DELAY) mode = "delay";
	else mode="--wrong-mode--";

	printf("Channel %i, mode %s, repeat %i %s\n",
	       FDELAY_OUTPUT_HW_TO_USER(channel), mode,
	       p->rep, p->rep == -1 ? "(infinite)" : "");
	report_time("start", &p->start);
	report_time("end  ", &p->end);
	report_time("loop ", &p->loop);
}
