#!/bin/false
# fastconf -- generic checks (autoconf-like)
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_check_init() {
	fc_inherit cc
	fc_export_functions \
		fc_mod_check_check_results

	set -- FC_CHECKED_FUNCS FC_CHECKED_LIBS FC_USED_LIBS \
		FC_CHECKED_HEADERS FC_CHECKED_PACKAGES FC_USED_PACKAGES
	unset ${*}
	fc_persist ${*}
}

# Synopsis: fc_check_def <name> <desc> <def> <comment>
fc_check_def() {
	echo "/* ${4} */"
	if fc_check "${1}" "${2}"; then
		fc_def "${3}" 1
	else
		echo "#undef ${3}"
	fi
	echo
}

fc_mod_check_check_results() {
	# fc_check_funcs()
	set -- ${FC_CHECKED_FUNCS}
	while [ ${#} -gt 0 ]; do
		fc_check_def "cf-${1}" "${1}()" "HAVE_$(fc_macro_clean "${1}")" \
			"define if your system has ${1}() function"
		shift
	done

	# fc_check_lib()
	set -- ${FC_CHECKED_LIBS}
	while [ ${#} -gt 0 ]; do
		fc_check_def "cl-${1}" "-l${1}" "HAVE_LIB$(fc_macro_clean "${1}")" \
			"define if your system has lib${1}"

		if fc_array_has "${1}" ${FC_USED_LIBS} && fc_check "cl-${1}"; then
			fc_array_append CONF_LIBS "-l${1}"
		fi
		shift
	done

	# fc_check_headers()
	set -- ${FC_CHECKED_HEADERS}
	while [ ${#} -gt 0 ]; do
		fc_check_def "ch-${1}.o" "${1}" "HAVE_$(fc_macro_clean "${1}")" \
			"define if your system has ${1}"
		shift
	done

	# fc_check_pkg_config_lib()
	set -- ${FC_CHECKED_PACKAGES}
	while [ ${#} -gt 0 ]; do
		fc_check_def "cp-${1}" "${1}" "HAVE_$(fc_macro_clean "${1}")" \
			"define if your system has ${1}"
		shift
	done

	# fc_use_pkg_config_lib()
	local pmacro plibs pldflags pcppflags
	set -- ${FC_USED_PACKAGES}
	while [ ${#} -gt 0 ]; do
		if fc_check "cp-${1}"; then
			pmacro=$(fc_macro_clean "${1}")
			eval "plibs=\${${pmacro}_LIBS}
				pldflags=\${${pmacro}_LDFLAGS}
				pcppflags=\${${pmacro}_CPPFLAGS}"

			fc_array_append CONF_LIBS "${plibs}"
			fc_array_append CONF_LDFLAGS "${pldflags}"
			fc_array_append CONF_CPPFLAGS "${pcppflags}"
		fi
		shift
	done
}

# Synopsis: fc_check_funcs <func> [...]
# Check for existence of passed functions. When the checks are done,
# HAVE_<func> macros will be defined in the header file, with <func>
# being the name of particular function transformed uppercase.
fc_check_funcs() {
	while [ ${#} -gt 0 ]; do
		fc_cc_try_link cf-"${1}" \
			"char ${1}();" "return ${1}();"
		fc_array_append FC_CHECKED_FUNCS "${1}"
		shift
	done
}

# Synopsis: fc_check_lib <basename> [<func>] [<ldflags>] [<other-libs>]
# Check for existence of passed library <basename> (without '-l'
# prefix), by trying to link with the library and find to function
# <func> afterwards. If <func> is not specified or empty (which is not
# recommended), no function check will be performed.
#
# The <ldflags> specify additional linker flags for the test and
# <other-libs> may provide an additional dependant library list
# (containing '-l' prefixes).
#
# When the check is done, HAVE_LIB<basename> (with <basename> being
# transformed uppercase) will be defined.
fc_check_lib() {
	fc_cc_try_link cl-"${1}" \
		'' "${2:+${2}(); }return 0;" \
		'' "-l${1}${4+ ${4}}" "${3}"
	fc_array_append FC_CHECKED_LIBS "${1}"
}

# Synopsis: fc_use_lib <basename> [<func>] [<ldflags>] [<other-libs>]
# Check for existence of passed library <basename> and append it to
# CONF_LIBS if available. For description of arguments and declared
# macro details, see fc_check_lib().
fc_use_lib() {
	fc_check_lib "${@}"
	fc_array_append FC_USED_LIBS "${1}"
}

# Synopsis: fc_check_headers <files> [<cppflags>] [<includes>]
# Check for existence of header files <files> (in the form
# 'filename.h'). Declare HAVE_<header-file> (where <header-file> is made
# 'macro-clean') if headers can be compiled against.
#
# <cppflags> specifies any additional compiler flags; <includes>
# specifies additional preprocessor directives required before
# the actual #include. <includes> is passed to 'printf %b', so it can
# use C escape sequences.
fc_check_headers() {
	while [ ${#} -gt 0 ]; do
		fc_cc_try_compile ch-"${1}" \
			"${3+${3}\n}#include <${1}>" "return 0;"
		fc_array_append FC_CHECKED_HEADERS "${1}"
		shift
	done
}

# Synopsis: fc_check_pkg_config_lib <package> [<func>] [<fallback-libs>] [<fallback-ldflags>]
# Check for existence of library(-ies) referenced by pkg-config package
# <package>, and afterwards declare HAVE_<package> (where <package> is
# transformed uppercase). <func> works like in fc_check_lib().
#
# If <fallback-libs> are provided, they will be used along with
# <fallback-ldflags> if pkg-config is unable to find the package.
# Otherwise, the function will behave as if the package was
# not available.
fc_check_pkg_config_lib() {
	local plibs pldflags
	# XXX: check for pkgconfig inherit
	# XXX: clean up <package> for naming

	# always append it so we always get at least undef
	fc_array_append FC_CHECKED_PACKAGES "${1}"

	if fc_pkg_config --exists "${1}"; then
		plibs=$(fc_pkg_config --libs-only-l "${1}")
		pldflags=$(fc_pkg_config --libs-only-L --libs-only-other "${1}")
	elif [ -n "${3+1}" ]; then
		plibs=${3}
		pldflags=${4}
	else
		return 1
	fi

	fc_cc_try_link cp-"${1}" \
		'' "${2:+${2}(); }return 0;" \
		'' "${plibs}" "${pldflags}"
}

# Synopsis: fc_use_pkg_config_lib <package> [<func>] [<fallback-libs>] [<fallback-ldflags>] [<fallback-cppflags>]
# Check for existence of library(-ies) referenced by pkg-config package
# <package>, declaring HAVE_<package> (where <package> is transformed
# uppercase) and appending necessary flags to CONF_{{CPP,LD}FLAGS,LIBS}
# if the check succeds.
#
# <func> and <fallback-*> arguments work the same
# as in fc_check_pkg_config_lib().
fc_use_pkg_config_lib() {
	local plibs pldflags pcppflags pfound pmacro
	# XXX: check for pkgconfig inherit
	# XXX: clean up <package> for naming

	pfound=1
	if fc_pkg_config --exists "${1}"; then
		plibs=$(fc_pkg_config --libs-only-l "${1}")
		pldflags=$(fc_pkg_config --libs-only-L --libs-only-other "${1}")
		pcppflags=$(fc_pkg_config --cflags "${1}")
	elif [ -n "${3+1}" ]; then
		plibs=${3}
		pldflags=${4}
		pcppflags=${5}
	else
		unset plibs pldflags pcppflags
		pfound=0
	fi

	pmacro=$(fc_macro_clean "${1}")
	eval "${pmacro}_LIBS=\${plibs}
			${pmacro}_LDFLAGS=\${pldflags}
			${pmacro}_CPPFLAGS=\${pcppflags}"
	fc_persist ${pmacro}_LIBS ${pmacro}_LDFLAGS ${pmacro}_CPPFLAGS

	# checked array to get defines, used to get macros
	fc_array_append FC_CHECKED_PACKAGES "${1}"

	if [ ${pfound} -eq 1 ]; then
		fc_array_append FC_USED_PACKAGES "${1}"
		fc_cc_try_link cp-"${1}" \
			'' "${2:+${2}(); }return 0;" \
			'' "${plibs}" "${pldflags}"
	fi
}
