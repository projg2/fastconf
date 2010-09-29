#!/bin/false
# fastconf -- common C/C++ compiler options
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_cc_common_init() {
	fc_export_functions \
		fc_mod_cc_common_help \
		fc_mod_cc_common_get_targets \
		fc_mod_cc_common_get_exports
}

fc_mod_cc_common_help() {
	cat <<_EOF_
	CPPFLAGS='<flag> ...'	C/C++ preprocessor flags (-I..., -D...)
	LDFLAGS='<flag> ...'	C/C++ linking flags (-L..., -Wl,...)
	LIBS='<flag> ...'	C/C++ libs to link with (-l...)

_EOF_
}

fc_mod_cc_common_get_targets() {
	fc_export CPPFLAGS "${CPPFLAGS}"
	fc_export LDFLAGS "${LDFLAGS}"
	fc_export LIBS "${LIBS}"
}

fc_mod_cc_common_get_exports() {
	fc_export CONF_CPPFLAGS "${CONF_CPPFLAGS}"
	fc_export CONF_LDFLAGS "${CONF_LDFLAGS}"
	fc_export CONF_LIBS "${CONF_LIBS}"
}
