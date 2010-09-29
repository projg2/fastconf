#!/bin/false
# fastconf -- pkg-config support macros
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_pkgconfig_init() {
	fc_inherit cc_common
	fc_export_functions \
		fc_mod_pkgconfig_help \
		fc_mod_pkgconfig_cmdline_parsed
}

fc_mod_pkgconfig_help() {
	cat <<_EOF_
	PKG_CONFIG=<name>	pkg-config command

_EOF_
}

fc_mod_pkgconfig_cmdline_parsed() {
	unset FC_PKGCONFIG_WARNED
}

# Synopsis: fc_pkg_config [...]
# Tries to find ${CHOST}-pkg-config or pkg-config, and calls it with
# supplied arguments. If it is unable to find any pkg-config, it outputs
# a warning and returns 127.
fc_pkg_config() {
	if [ -z "${PKG_CONFIG}" ]; then
		if [ -z "${FC_PKGCONFIG_WARNED}" ]; then
			if [ -n "${CHOST}" ] && fc_have "${CHOST}"-pkg-config; then
				PKG_CONFIG=${CHOST}-pkg-config
			elif fc_have pkg-config; then
				PKG_CONFIG=pkg-config

				if [ "${CBUILD}" != "${CHOST}" ]; then
					echo "WARNING: cross-compiling but no ${CHOST}-pkg-config found." >&2
				fi
			else
				echo "WARNING: pkg-config not found." >&2
				FC_PKGCONFIG_WARNED=1
				return 127
			fi
		else
			return 127
		fi
	fi

	"${PKG_CONFIG}" "${@}"
}

# Synopsis: fc_use_pkg_config <package>
# Query pkg-config about package <package> and append the obtained
# information to CONF_{{CPP,LD}FLAGS,LIBS}. Return true if pkg-config
# call succeded, false otherwise.
fc_use_pkg_config() {
	if fc_pkg_config --exists "${1}"; then
		fc_array_append CONF_CPPFLAGS "$(fc_pkg_config --cflags "${1}")"
		fc_array_append CONF_LDFLAGS "$(fc_pkg_config --libs-only-L --libs-only-other "${1}")"
		fc_array_append CONF_LIBS "$(fc_pkg_config --libs-only-l "${1}")"
	fi
}
