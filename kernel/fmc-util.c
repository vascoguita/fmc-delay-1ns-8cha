/*
 * Some utility functions not supported in the current version of fmc-bus.
 *
 * Copyright (C) 2012-2014 CERN (www.cern.ch)
 * Author: Tomasz Wlostowski <tomasz.wlostowski@cern.ch>
 * Author: Alessandro Rubini <rubini@gnudd.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2 as published by the Free Software Foundation or, at your
 * option, any later version.
*/

#include <linux/fmc.h>
#include <linux/fmc-sdb.h>
#include <linux/err.h>
#include <asm/byteorder.h>

#include "fine-delay.h"

typedef int (*sdb_traverse_cb) (uint32_t address, uint32_t size, uint64_t vid, uint32_t did, void *data);

static int traverse_sdb_devices(struct sdb_array *tree,
				sdb_traverse_cb cb,
				void *data)
{
	union sdb_record *r;
	struct sdb_product *p;
	struct sdb_component *c;
	int i, n = tree->len, rv;
	uint64_t last, first, vid;
	uint32_t did, size;

	/* FIXME: what if the first interconnect is not at zero? */
	for (i = 0; i < n; i++) {
		r = &tree->record[i];
		c = &r->dev.sdb_component;
		p = &c->product;

		if (!IS_ERR(tree->subtree[i]))
		{
			rv = traverse_sdb_devices ( tree->subtree[i], cb, data );
			if(rv > 0)
				return 1;
		}

		if (r->empty.record_type != sdb_type_device)
			continue;

		/* record is a device?*/
		last = __be64_to_cpu(c->addr_last);
		first = __be64_to_cpu(c->addr_first);
		vid = __be64_to_cpu(p->vendor_id);
		did = __be32_to_cpu(p->device_id);
		size = (uint32_t) (last + 1 - first);

		if (cb (first + tree->baseaddr, size, vid, did, data))
		    return 1;
	}
    return 0;
}

struct callback_state {
    int n;
    int *ordinal;
    uint32_t current_address;
    uint32_t current_size;
    uint64_t did;
    uint32_t vid;
};

static int callback (uint32_t address, uint32_t size, uint64_t vid_, uint32_t did_, void *data)
{
	struct callback_state *st = (struct callback_state *) data;
	if(vid_ == st->vid && did_ == st->did)
	{
	    st->n++;
	    st->current_address = address;
	    st->current_size = size;

	    if(!st->ordinal || st->n == *st->ordinal)
	    {
		return 1;
	    }
	}
	return 0; /* continue scanning	*/
}

/* Finds the Nth SDB device that matches (vid/did) pair, where N <= *ordinal.
   If N < *ordinal, the value of N is stored at *ordinal.
   This magic is used to handle hybrid bistreams (with two or more different
   mezzanines). */

signed long fmc_sdb_find_nth_device (struct sdb_array *tree, uint64_t vid, uint32_t did, int *ordinal, uint32_t *size )
{
    struct callback_state st;

    st.n = -1;
    st.ordinal = ordinal;
    st.vid = vid;
    st.did = did;

    traverse_sdb_devices (tree, callback, &st);

    if (st.n >= 0)
    {
	if(size)
	    *size = st.current_size;
	if(ordinal)
	    *ordinal = st.n;

	return st.current_address;
    }

    return -ENODEV;
}
