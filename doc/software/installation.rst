============
Installation
============

This driver depends on four other modules (four http://ohwr.org.}
packages), as well as the Linux kernel.  Also, it
must talk to a specific FPGA binary file running in the device.

Gateware Dependencies
=====================

While previous versions of this package included a gateware binary
in the ``binaries/`` subdirectory, in Jan 2014 we decided not to do
that any more.  Release versions of this package are expected to
point to ``current`` gateware images for different carriers.
Clearly the driver is expected to work on any *fmc* carrier,
even those ignored to us, and we can't provide all binaries.

The up-to-date gateware binaries for the SVEC and SPEC carriers will be
always available in the *Releases* section of the Fine Delay project:
http://www.ohwr.org/projects/fmc-delay-1ns-8cha/wiki/Releases

Note that the release gateware contains a stable version of
the White Rabbit PTP Core firmware. This firmware may be reloaded dynamically
at any time using carrier-specific tools.

Gateware Installation
=====================

By default, the driver looks for a gateware file named
``/lib/firmware/fmc/[carrier]-fine-delay.bin``, where ``[carrier]`` is the
carrier's name (lowercase - currently ``svec`` or ``spec``). There are two ways
to install the gateware:

* The easy way: run ``make gateware_install`` in the target system. This will
  automatically download all required files and install them in the right
  place.

* The difficult way: download the bitstreams from the Release page (or build
  your own, as you wish) and put them in ``/lib/firmware/fmc``. You may have
  to strip the version/date attached to the file names or create symlinks.

If you have several *fine-delay* cards in the same host, you can
load different binaries for different cards, using appropriate
module parameters. Loading custom gateware files
is advised only for advanced users/developers.

Software Dependencies
=====================

The kernel versions I am using during development is 3.4.  Everything
used here is known to build with all versions from 2.6.35 to 3.12.

The driver, then, is based on the *zio* framework, available from
http://ohwr.org.. This version of *zio* doesn't build with 3.13, for
a minor incompatibility, so this version of *fine-delay-sw* is
limited to Linux 3.12 as well.

The FMC mezzanine is supported by means of the *fmc-bus*
software project. This *fine-delay* kernel module registers as
a *driver* for the FMC bus abstraction, and is verified with
version ``v2014-02`` of the FMC package. The same kernel range applies.

Both packages (*zio* and *fmc-bus*) are currently checked out as
*git submodules* of this package, and each of them is retrieved at
the right version to be compatible with this driver.  This means you may just
ignore software dependencies and everything should work.

*fmc* support is a *bus* in the Linux way, so you need both
a *device* and a *driver*. This driver is known to work both
with the *spec* carrier on *pci* and the *svec* carrier
on *vme*. The software packages that provide the respective *device*
are called *spec-sw* and *svec-sw*; both are hosted on http://ohwr.org.

Most of the non-*cern* users are expected to run the *spec*
carrier, so a compatible version of *spec-sw* is downloaded
as a submodule, too.

Software Installation
=====================

To install this software package, you need to tell it where your
kernel sources live, so the package can pick the right header files.
You need to set only one environment variable:

LINUX

	The top-level directory of the Linux kernel you are compiling
        against. If not set, the default may work if you compile in the same
        host where you expect to run the driver.


Most likely, this is all you need to set. After this, you can
run:::

    make
    sudo make install gateware_install LINUX=$LINUX

In addition to the normal installation procedure for
``fmc-fine-delay.ko`` you'll see the following message:::

    WARNING: Consider "make prereq_install"

The *prerequisite* packages are *zio* and *fmc-bus*;
unless you already installed your own preferred version, you are
expected to install the version this packages suggests. This step
can be performed by:::

    make
    sudo make prereq_install LINUX=$LINUX

The step is not performed by default to avoid overwriting some
other versions of the drivers. After ``make prereq_install``,
the warning message won't be repeated any more if you change this
driver and ``make install`` again.

After installation, your carrier driver should load automatically
(for example, the PCI bus will load ``spec.ko``), but ``fmc-fine-delay.ko``
must be loaded manually, because support for automatic loading is not
yet in place. The suggested command is one or the other of the following two:::

   modprobe fmc-fine-delay [<parameter> ...]         # after make install
   insmod kernel/fmc-fine-delay.ko [<parameter> ...]  # if not installed


Available module parameters are described in :ref:`Module Parameters<drv_param>`.
Unless you customized or want to customize one of the three
related packages, you can skip the rest of this section.

In order to compile *fine-delay* against a specific repository of one
of the related packages, ignoring the local *submodule*
you can use one or more of the following environment variables:

* ZIO, FMC_BUS, SPEC_SW
	The top-level directory of the repository checkout of each
        package. Most users won't need to set them, as the Makefiles
        point them to the proper place by default.


If any of the above is set, headers and dependencies for the
respective package are taken from the chosen directory. If you
``make prereq_install`` with any of these variables set, they are
be used to know where to install from, instead of using local submodules.
