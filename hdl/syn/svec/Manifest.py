# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

board  = "svec"
target = "xilinx"
action = "synthesis"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"
syn_top = "svec_top"
syn_project = "svec_fine_delay.xise"
syn_tool    = "ise"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
    fetchto = "../../ip_cores"

# Ideally this should be done by hdlmake itself, to allow downstream Manifests to be able to use the
# fetchto variable independent of where those Manifests reside in the filesystem.
import os
fetchto = os.path.abspath(fetchto)

files = [
    "buildinfo_pkg.vhd",
    "sourceid_svec_fine_delay_top_pkg.vhd",
    "svec_fine_delay_top.ucf",
    "svec-fd0.ucf",
    "svec-fd1.ucf"
]

modules = {
    "local" : [
        "../../top/svec",
    ],
}

# Do not fail during hdlmake fetch
try:
  exec(open(fetchto + "/general-cores/tools/gen_buildinfo.py").read())
except:
  pass

try:
    # Assume this module is in fact a git submodule of a main project that
    # is in the same directory as general-cores...
    exec(open(fetchto + "/general-cores/tools/gen_sourceid.py").read(),
         None, {'project': 'svec_fine_delay_top'})
except Exception as e:
    print("Error: cannot generate source id file")
    raise


syn_post_project_cmd = "$(TCL_INTERPRETER) syn_extra_steps.tcl $(PROJECT_FILE)"

svec_base_ucf = ['wr', 'led', 'gpio']

ctrls = ["bank4_64b_32b", "bank5_64b_32b"]
