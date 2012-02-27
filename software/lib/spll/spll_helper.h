
/* State of the Helper PLL producing a clock (clk_dmtd_i) which is
   slightly offset in frequency from the recovered/reference clock (clk_rx_i or clk_ref_i), so the
   Main PLL can use it to perform linear phase measurements. This structure keeps the state of the pre-locking
   stage */
struct spll_helper_prelock_state {
 	spll_pi_t pi;
 	spll_lock_det_t ld;
 	int f_setpoint;
	int ref_select;
	fdelay_device_t *dev;
};


volatile int serr;

void helper_prelock_init(struct spll_helper_prelock_state *s)
{

	/* Frequency branch PI controller */
	s->pi.y_min = 5;
	s->pi.y_max = 65530;
	s->pi.anti_windup = 0;
	s->pi.kp = 28*32*16;
	s->pi.ki = 50*32*16;
	s->pi.bias = 32000;

	/* Freqency branch lock detection */
	s->ld.threshold = 2;
	s->ld.lock_samples = 1000;
	s->ld.delock_samples = 990;

	s->f_setpoint = 131072 / (1<<HPLL_N);

	pi_init(&s->pi);
	ld_init(&s->ld);
}


void helper_prelock_enable(struct spll_helper_prelock_state *state, int ref_channel, int enable)
{
	fdelay_device_t *dev = state->dev;
	fd_decl_private(dev);

	fd_writel(0, FD_REG_SPLLR);
}

#define SPLL_LOCKED 1
#define SPLL_LOCKING 0

int helper_prelock_update(struct spll_helper_prelock_state *s, int tag)
{
	fdelay_device_t *dev = s->dev;
	fd_decl_private(dev);

	int y;
	volatile uint32_t per = fd_readl(FD_REG_SPLLR);

	short err = (short) (tag & 0xffff);
	serr = (int)err;

	err -= s->f_setpoint;

	y = pi_update(&s->pi, err);
	fd_writel(y, FD_REG_SDACR);

	if(ld_update(&s->ld, err))
		return SPLL_LOCKED;

	return SPLL_LOCKING;
}

struct spll_helper_phase_state {
 	spll_pi_t pi;
 	spll_lock_det_t ld;
 	int p_setpoint, tag_d0;
 	int ref_src;
 	fdelay_device_t *dev;
};

void helper_phase_init(struct spll_helper_phase_state *s)
{

	/* Phase branch PI controller */
	s->pi.y_min = 5;
	s->pi.y_max = 65530;
 	s->pi.kp = (int)(2.0 * 32.0 * 16.0);
	s->pi.ki = (int)(0.05 * 32.0 * 3.0);
	s->pi.anti_windup = 0;
	s->pi.bias = 32000;

	/* Phase branch lock detection */
	s->ld.threshold = 500;
	s->ld.lock_samples = 10000;
	s->ld.delock_samples = 9900;
	s->ref_src = 6;
	s->p_setpoint = -1;
	pi_init(&s->pi);
	ld_init(&s->ld);
}

void helper_phase_enable(struct spll_helper_phase_state *state, int ref_channel, int enable)
{
	fdelay_device_t *dev = state->dev;

	fd_decl_private(dev);
	fd_writel(FD_SPLLR_MODE, FD_REG_SPLLR);
}

volatile int delta;

int helper_phase_update(struct spll_helper_phase_state *s, int tag, int source)
{
	fdelay_device_t *dev = s->dev;
	fd_decl_private(dev);

	int err, y;

	serr = source;

//	if(source == s->ref_src)
	{
		if(s->p_setpoint < 0)
		{
		 	s->p_setpoint = tag;
		 	return;
		}

		err = tag - s->p_setpoint;
		delta = tag - s->tag_d0;

		s->tag_d0 = tag;
		s->p_setpoint += (1<<HPLL_N);
		if(s->p_setpoint > (1<<TAG_BITS))
			s->p_setpoint -= (1<<TAG_BITS);

		y = pi_update(&s->pi, err);
		//printf("t %d sp %d\n", tag, s->p_setpoint);

		fd_writel(y, FD_REG_SDACR);

		if(ld_update(&s->ld, err))
		{
			return SPLL_LOCKED;
		};
	}

	return SPLL_LOCKING;
}

#define HELPER_PRELOCKING 1
#define HELPER_PHASE 2
#define HELPER_LOCKED 3

struct spll_helper_state {
	struct spll_helper_prelock_state prelock;
	struct 	spll_helper_phase_state phase;
	int state;
	int ref_channel;
};

void helper_start(fdelay_device_t *dev, struct spll_helper_state *s)
{
	s->state = HELPER_PRELOCKING;
	s->ref_channel = 0;

	s->prelock.dev = dev;
	s->phase.dev = dev;

	helper_prelock_init(&s->prelock);
	helper_phase_init(&s->phase);

	helper_prelock_enable(&s->prelock, 0, 1);

}

void helper_update(struct spll_helper_state *s)
{
	fdelay_device_t *dev = s->prelock.dev;
	fd_decl_private(dev);


	uint32_t spllr = fd_readl(FD_REG_SPLLR);

	if(! (spllr & FD_SPLLR_TAG_RDY))
		return;

	int tag = FD_SPLLR_TAG_R(spllr);

	switch(s->state)
	{
		case HELPER_PRELOCKING:
			if(helper_prelock_update(&s->prelock, tag) == SPLL_LOCKED)
			{
				s->state = HELPER_PHASE;
				helper_prelock_enable(&s->prelock, 0, 0);
				s->phase.pi.bias = s->prelock.pi.y;
				helper_phase_enable(&s->phase, 0, 1);
			}
		break;
		case HELPER_PHASE:
			helper_phase_update(&s->phase, tag, 0);
		break;
	}
}

