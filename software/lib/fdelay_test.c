#include <stdio.h>

#include "fdelay_lib.h"
#include "rr_io.h"

extern int spec_fdelay_init(int argc, char *argv[], fdelay_device_t *dev);

main(int argc, char *argv[])
{
    fdelay_device_t dev;

    /* Initialize the fine delay generator */
    if(spec_fdelay_init(argc, argv, &dev) < 0)
    {
        fdelay_show_test_results();
        return -1;
    }

    /* Enable trigger input and 50 ohm termination */
    fdelay_configure_trigger(&dev, 1,1);

    /* Enable all outputs and set them to 500 ns delay, 100 ns pulse width, single output pulse per trigger */
    fdelay_configure_output(&dev,1,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,2,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,3,1,500000, 100000, 100000, 1);
    fdelay_configure_output(&dev,4,1,500000, 100000, 100000, 1);

}
