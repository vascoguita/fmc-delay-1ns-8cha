#include <stdio.h>

#include "fdelay_lib.h"

main(int argc, char *argv[])
{
    fdelay_device_t dev;

    /* Initialize the fine delay generator */
    if(spec_fdelay_create(&dev, argc, argv) < 0)
    {
     	printf("Probe failed.\n");
        return -1;
    }

    if(fdelay_init(&dev, 0) < 0)
    {
     	printf("Init failed.\n");
        return -1;
    }

	fdelay_dmtd_calibration(&dev, NULL);

	return 0;
}
