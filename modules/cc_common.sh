#!/bin/false
# fastconf -- common C/C++ compiler options
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_cc_common_init() {
	fc_export_functions \
		fc_mod_cc_common_cmdline_parsed \
		fc_mod_cc_common_get_targets
}

fc_mod_cc_common_cmdline_parsed() {
	unset PKGCONFIG_WARNED
}

fc_mod_cc_common_get_targets() {
	fc_export CPPFLAGS "${CPPFLAGS}"
	fc_export LDFLAGS "${LDFLAGS}"
}

# Synopsis: fc_pkg_config [...]
# Tries to find ${CHOST}-pkg-config or pkg-config, and calls it with
# supplied arguments. If it is unable to find any pkg-config, it outputs
# a warning and returns 127.
fc_pkg_config() {
	if [ -z "${PKGCONFIG}" ]; then
		if [ -z "${PKGCONFIG_WARNED}" ]; then
			if [ -n "${CHOST}" ] && fc_have "${CHOST}"-pkg-config; then
				PKGCONFIG=${CHOST}-pkg-config
			elif fc_have pkg-config; then
				PKGCONFIG=pkg-config

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

	"${PKGCONFIG}" "${@}"
}
