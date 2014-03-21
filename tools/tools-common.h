/*
 * Simple code that is repeated over several tools
 */

extern void tools_getopt_d_i(int argc, char **argv,
			     int *dev, int *index);
extern int  tools_need_help(int argc, char **argv);
extern void report_time(char *name, struct fdelay_time *t);
extern void tools_report_action(int channel, struct fdelay_pulse *p);

extern void help(char *name); /* This is mandatory in all tools */
