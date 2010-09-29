#!/bin/false
# fastconf -- generic checks (autoconf-like)
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_check_init() {
	fc_inherit cc
	fc_export_functions \
		fc_mod_check_check_results

	set -- FC_CHECKED_FUNCS FC_CHECKED_LIBS FC_USED_LIBS
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
		fc_check_def "cf-${1}" "${1}()" "HAVE_$(fc_uc "${1}")" \
			"define if your system has ${1}() function"
		shift
	done

	# fc_check_lib()
	set -- ${FC_CHECKED_LIBS}
	while [ ${#} -gt 0 ]; do
		fc_check_def "cl-${1}" "-l${1}" "HAVE_LIB$(fc_uc "${1}")" \
			"define if your system has lib${1}"

		if fc_array_has "${1}" ${FC_USED_LIBS} && fc_check "cl-${1}"; then
			fc_array_append CONF_LIBS "-l${1}"
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
			'' "${1}(); return 0;"
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
