/* Temperature calibration test program. 

	Requires a PWM-driven peltier cooler placed over the delay line chips, PWM drive connected to MOSI pin */

#include <stdio.h>
#include <stdint.h>
#include <math.h>

#include "fdelay_lib.h"
#include "fdelay_private.h"
#include "fd_main_regs.h"

#include "onewire.h"

typedef struct {
   float kp, ki, err, pwm, setpoint, i, bias;
} pi_t;

pi_t pi_state = {15.0, 5.0, 0, 0, 20, 0, 2048};


void pi_update(fdelay_device_t *dev, float temp)
{
    fd_decl_private(dev);
    
    pi_state.err = temp - pi_state.setpoint;
    pi_state.i += pi_state.err;
    pi_state.pwm = pi_state.bias + pi_state.kp * pi_state.err + pi_state.ki * pi_state.i;
    
    dbg("t %.1f err:%.1f DRIVE: %d\n", temp, pi_state.err, (int)pi_state.pwm);
    
    fd_writel((int)pi_state.pwm, FD_REG_TDER2);
}

extern int64_t get_tics();

static int64_t last_tics = 0;

#define TEMP_REG_PERIOD 1000000LL

int pi_set_temp(fdelay_device_t *dev, float new_temp)
{
    int temp;
    float temp_f;
    
    if(get_tics() - last_tics < TEMP_REG_PERIOD)
        return 0;
        
    last_tics = get_tics();
    
    if(ds18x_read_temp(dev, &temp) < 0)
        return 0;

    temp_f = (float)temp / 16.0;
        
    pi_state.setpoint = new_temp;
    pi_update(dev, temp_f);
        
    dbg("Temperature: %.1f degC err %.1f\n", temp_f, pi_state.err);
    return fabs(pi_state.err) < 0.1 ? 1: 0;
}

main(int argc, char *argv[])
{
	fdelay_device_t dev;

	if(spec_fdelay_create(&dev, argc, argv) < 0)
	{
		fprintf(stderr,"Card probe failed.\n");
		return -1;
	}	
	
	if(fdelay_init(&dev, 0) < 0)
	{
		fprintf(stderr,"Card init failed.\n");
		return -1;
    }
    
    float t_min = 40.0, t_max = 80.0, t_cur;
    
    t_cur = t_min;

    for(;;)
    {
        if(pi_set_temp(&dev, t_cur))
        {
			fdelay_device_t *b = &dev;
            fd_decl_private(b);

            calibrate_outputs(&dev);
            fprintf(stderr, "> %.1f %d %d %d %d\n", t_cur, hw->frr_cur[0],
             hw->frr_cur[1], hw->frr_cur[2], hw->frr_cur[3]);
             t_cur += 1.0;
             if(t_cur > t_max)
             break;
        }
        
        usleep(10000);
    }

}
