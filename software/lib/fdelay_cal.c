#include <stdio.h>
#include <stdint.h>

#include "fdelay_lib.h"
#include "fdelay_private.h"
#include "fd_main_regs.h"

#include "onewire.h"
#include "rr_io.h"

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
    
    fd_writel(FD_I2CR_DBGOUT_W((int)pi_state.pwm), FD_REG_I2CR);
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

void my_writel(void *priv, uint32_t data, uint32_t addr)
{
 	rr_writel(data, addr);
}

uint32_t my_readl(void *priv, uint32_t addr)
{
	uint32_t d = rr_readl(addr);
	return d;
}

main()
{
	fdelay_device_t *dev = malloc(sizeof(fdelay_device_t));

	rr_init(RR_DEVSEL_UNUSED, RR_DEVSEL_UNUSED);

	dev->writel = my_writel;
	dev->readl = my_readl;
	dev->base_addr = 0x80000;

	if(fdelay_init(dev) < 0)
		return -1;

    float t_min = 40.0, t_max = 80.0, t_cur;
    
    t_cur = t_min;

    for(;;)
    {
        if(pi_set_temp(dev, t_cur))
        {
            fd_decl_private(dev);

            calibrate_outputs(dev);
            fprintf(stderr, "> %.1f %d %d %d %d\n", t_cur, hw->frr_cur[0],
             hw->frr_cur[1], hw->frr_cur[2], hw->frr_cur[3]);
             t_cur += 1.0;
             if(t_cur > t_max)
             break;
        }
        
        usleep(10000);
    }

}
