#include <stdio.h>

#include "board.h"
#include "hw/softpll_regs.h"

#include "irq.h"

static volatile struct SPLL_WB *SPLL = (volatile struct SPLL_WB *) BASE_SOFTPLL;

/* The includes below contain code (not only declarations) to enable the compiler
   to inline functions where necessary and save some CPU cycles */
#include "spll_defs.h"
#include "spll_common.h"
#include "spll_helper.h"



volatile int irq_count = 0,eee,yyy;

struct spll_helper_state helper;

void _irq_entry()
{
	volatile uint32_t trr;
	int src = -1, tag;
	if(! (SPLL->CSR & SPLL_TRR_CSR_EMPTY))
	{
		trr = SPLL->TRR_R0;
		src = SPLL_TRR_R0_CHAN_ID_R(trr);
		tag = SPLL_TRR_R0_VALUE_R(trr);
		eee = tag;
	}

		helper_update(&helper, tag, src);
		yyy=helper.phase.pi.y;
		irq_count++;
		clear_irq();
}

void spll_init()
{
	volatile int dummy;
	disable_irq();

	SPLL->CSR= 0 ;
	SPLL->OCER = 0;
	SPLL->RCER = 0;
	SPLL->DEGLITCH_THR = 2000;
	while(! (SPLL->TRR_CSR & SPLL_TRR_CSR_EMPTY)) dummy = SPLL->TRR_R0;
	dummy = SPLL->PER_HPLL;
	SPLL->EIC_IER = 1;
}

void spll_test()
{
	int i = 0;
	volatile	int dummy;

	spll_init();
	helper_start(&helper, 6);
	enable_irq();

	for(;;)
	{
		mprintf("cnt %d serr %d src %d y %d d %d\n", irq_count, eee, serr, yyy, delta);
	}

}