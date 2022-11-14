# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

target = "xilinx"
action = "synthesis"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"
syn_project = "spec_fine_delay_top.xise"
syn_tool = "ise"
syn_top = "spec_fine_delay_top"

spec_base_ucf = ['wr', 'onewire', 'spi']
board = "spec"
ctrls = ["bank3_64b_32b" ]

files = [ "buildinfo_pkg.vhd", "sourceid_spec_fine_delay_top_pkg.vhd" ]

modules = {
    "local" : [ "../../top/spec" ]
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
         None, {'project': 'spec_fine_delay_top'})
except Exception as e:
    print("Error: cannot generate source id file")
    raise


syn_post_project_cmd = "$(TCL_INTERPRETER) syn_extra_steps.tcl $(PROJECT_FILE)"
