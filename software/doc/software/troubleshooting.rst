===============
Troubleshooting
===============

This chapters lists a few errors that may happen and how to deal with
them.

make modules_install misbehaves
===============================

The command ``sudo make modules_install`` may place the modules in the wrong
directory or fail with an error like:::

   make: \*\*\* /lib/modules/3.10/build: No such file or directory.

This happens when you compiled by setting ``KERNELSRC=`` and your
*sudo* is not propagating the environment to its child processes.
In this case, you should run this command instead::

   sudo make modules_install KERNELSRC=$KERNELSRC

Version Mismatch
================

The *fdelay* library may report a version mismatch like this:::

   spusa# ./tools/fmc-fdelay-board-time  -d 0x5 get
   Incompatible version driver-library

This reports a difference in the way ZIO attributes are laid out, so user
space may exchange wrong data in the ZIO control block, or may try to
access inexistent files in */sys*. I suggest recompiling both the kernel
driver and user space from a single release of the source package.
