#!/bin/false
# fastconf -- common C/C++ compiler options
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_cc_common_init() {
	fc_export_functions \
		fc_mod_cc_common_get_targets
}

fc_mod_cc_common_get_targets() {
	fc_export CPPFLAGS "${CPPFLAGS}"
	fc_export LDFLAGS "${LDFLAGS}"
}
