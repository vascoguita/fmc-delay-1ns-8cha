============
Installation
============

This driver depends on two other modules (four http://ohwr.org.
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
carrier's name (lowercase - currently ``svec`` or ``spec``).

To install the gateware download the bitstreams from the Release page (or build
your own, as you wish) and put them in ``/lib/firmware/fmc``. You may have
to strip the version/date attached to the file names or create symlinks.

Follow your carrier instructions to load the gateware on the FPGA.

Software Dependencies
=====================

The kernel versions I am using during development is 3.10.  Everything
used here is known to build with all versions from 2.6.35 to 3.12.

The driver, then, is based on the `zio`_ framework, available from
http://ohwr.org.

The FMC mezzanine is supported by means of the `fmc`_ software project.

Both packages (`zio`_ and `fmc`_) need to be downloaded and compiled. We do not
provide submodules because their version may conflict with other projects.
It is duty of the final user to guarantee a consistent installation.

Software Installation
=====================

To install this software package, you need to tell it where your
kernel sources live, so the package can pick the right header files.
You need to set only one environment variable:

KERNELSRC
  The top-level directory of the Linux kernel you are compiling
  against. If not set, the default may work if you compile in the same
  host where you expect to run the driver.


Most likely, this is all you need to set. After this, you can
run:::

    make
    sudo make install KERNELSRC=$KERNELSRC

After installation, your carrier driver should load automatically
(for example, the PCI bus will load ``spec-fmc-carrier.ko``), but
``fmc-fine-delay.ko`` must be loaded manually, because support for automatic
loading is not yet in place. The suggested command is one or the other of
the following two:::

   modprobe fmc-fine-delay [<parameter> ...]         # after make install
   insmod kernel/fmc-fine-delay.ko [<parameter> ...]  # if not installed


Available module parameters are described in :ref:`Module Parameters<drv_param>`.
Unless you customized or want to customize one of the three
related packages, you can skip the rest of this section.

In order to compile *fine-delay* against a specific repository you can use
the following environment variables:

ZIO
  The top-level directory of the repository checkout of each
  package.

FMC
  The top-level directory of the repository checkout of each
  package.

Headers and dependencies for the respective package are taken from the chosen
directory.

.. _zio: https://www.ohwr.org/project/zio
.. _fmc: https://www.ohwr.org/project/fmc-sw
