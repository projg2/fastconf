#!/bin/false
# fastconf -- common C/C++ compiler options
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_cc_common_init() {
	fc_export_functions \
		fc_mod_cc_common_help \
		fc_mod_cc_common_cmdline_parsed \
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

fc_mod_cc_common_cmdline_parsed() {
	unset PKGCONFIG_WARNED
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

# Synopsis: fc_pkg_config [...]
# Tries to find ${CHOST}-pkg-config or pkg-config, and calls it with
# supplied arguments. If it is unable to find any pkg-config, it outputs
# a warning and returns 127.
fc_pkg_config() {
	if [ -z "${PKG_CONFIG}" ]; then
		if [ -z "${PKGCONFIG_WARNED}" ]; then
			if [ -n "${CHOST}" ] && fc_have "${CHOST}"-pkg-config; then
				PKG_CONFIG=${CHOST}-pkg-config
			elif fc_have pkg-config; then
				PKG_CONFIG=pkg-config

				if [ "${CBUILD}" != "${CHOST}" ]; then
					echo "WARNING: cross-compiling but no ${CHOST}-pkg-config found." >&2
				fi
			else
				echo "WARNING: pkg-config not found." >&2
				PKGCONFIG_WARNED=1
				return 127
			fi
		else
			return 127
		fi
	fi

	"${PKG_CONFIG}" "${@}"
}
