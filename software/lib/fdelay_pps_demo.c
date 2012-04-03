#include <stdio.h>

#include "fdelay_lib.h"

int spec_fdelay_init(int argc, char *argv[], fdelay_device_t *dev);

main(int argc, char *argv[])
{
	fdelay_device_t dev;
    fdelay_time_t t_cur, t_start;

    if(spec_fdelay_init(argc, argv, &dev) < 0)
        return -1;
    
    // Get the current time of the FD core - and program the card to start producing the PPS and 10 MHz one second later */
    fdelay_get_time(&dev, &t_cur);
    
    printf("Current Time: %lld:%d\n", t_cur.utc, t_cur.coarse);
    
    t_start.coarse = t_cur.coarse;
    t_start.utc = t_cur.utc+1;
    t_start.frac = 0;
    
    fdelay_configure_pulse_gen(&dev, 1, 1, t_start, 48000LL, 100000LL, -1); /* Output 1, period = 100 ns, width = 48 ns - a bit asymmetric 10 MHz */
    fdelay_configure_pulse_gen(&dev, 2, 1, t_start, 48000LL, 1000000000000LL, -1); /* Output 2: period = 1 second, width = 48 ns - PPS signal */

    while(!fdelay_channel_triggered(&dev, 1) || fdelay_channel_triggered(&dev, 2))
        usleep(10000); /* wait until both outputs have triggered*/;
    return 0;
}
