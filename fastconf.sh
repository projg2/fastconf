#!/bin/false
# fastconf basic definitions file
# Do not call directly, source within the ./configure script instead.
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

_fc_unexpected_exit() {
	echo "ERROR: fastconf is exiting unexpectedly. This means you've probably hit" >&2
	echo "an internal error. Please run through 'sh -x ./configure' too see more." >&2
}

trap _fc_unexpected_exit EXIT

# You are free to redefine FC_MODULE_PATH wherever you'd like fastconf
# to use modules from.
: ${FC_MODULE_PATH=./modules}
FC_API=0
FC_API_MIN=0

# basic use checks

# The configure script should set PN and PV to the program name
# and version respectively before sourcing fastconf.sh, e.g.:
#	PN=foobar
#	PV=0.0.1
#	. ./fastconf.sh

if [ -z "${PN}" -o -z "${PV}" ]; then
	echo 'IMPORTANT: Please set ${PN} and ${PV} in the configure script!' >&2

	# We can try to guess PN but not PV.
	if [ -z "${PN}" ]; then
		PN=$(basename "${PWD}")
		echo "Falling back to PN=${PN}" >&2
	fi

	if [ -z "${PV}" ]; then
		PACKAGE=${PN}
	else
		PACKAGE=${PN}-${PV}
	fi
	echo "Guessing PACKAGE=${PACKAGE}" >&2
else
	PACKAGE=${PN}-${PV}
fi

# Set in order to enable configure phase.
: ${FC_CONFIG_H}
# Set in order to enable Makefile.in appending.
: ${FC_MAKEFILE_IN}
# Set to the expected FC_API version.
: ${FC_API_WANT}

unset FC_EXPORTED_FUNCTIONS FC_INHERITED

# Synopsis: fc_exit [code]
# Terminate the configure script cleanly.
fc_exit() {
	trap - EXIT
	exit "${@}"
}

_fc_sigexit() {
	echo 'Terminating due to a signal.' >&2
	fc_exit 3
}

trap _fc_sigexit HUP INT QUIT ABRT KILL TERM

# Synopsis: fc_export_functions <func> [...]
# Add the function <func> and the following functions to the exported
# function list. The functions have to resemble the conf_* naming scheme
# (for ./configure script) or fc_mod_* one (for modules).
fc_export_functions() {
	fc_array_append FC_EXPORTED_FUNCTIONS "${@}"
}

# Synopsis: _fc_check_exports
_fc_check_exports() {
	local f sf found
	# Obligatory exports:
	set -- get_targets

	while [ ${#} -gt 0 ]; do
		found=1
		for f in ${FC_EXPORTED_FUNCTIONS}; do
			sf=${f%_${1}}
			if [ ${sf} = conf -o ${sf#fc_mod_} != ${sf} ]; then
				found=0
				break
			fi
		done

		if [ ${found} -eq 1 ]; then
			echo "ERROR: Obligatory function ${1} not exported." >&2
			echo "Did you forget 'fc_export_functions conf_${1}? (assuming you did)" >&2
			fc_export_functions conf_get_targets
		fi

		shift
	done
}

# Synopsis: _fc_call_exports <func> [<arg1>] [...]
# Call all exported variants of <func> function (either conf_<func>
# or fc_mod_*_<func>). Returns true if at least one call succeded.
_fc_call_exports() {
	local funcname f ret
	funcname=${1}
	ret=1
	shift

	for f in ${FC_EXPORTED_FUNCTIONS}; do
		case ${f} in
			conf_${funcname}|fc_mod_*_${funcname})
				${f} "${@}" && ret=0
		esac
	done

	return ${ret}
}

# Synopsis: _fc_inherit <module>
# Internal fc_inherit() variant not relying on complete shell feature
# set (used to inherit _shutils).
_fc_inherit() {
	if [ -f "${FC_MODULE_PATH}/${1}.sh" ]; then
		. "${FC_MODULE_PATH}/${1}.sh"

		if ! fc_mod_${1}_init; then
			echo "FATAL ERROR: unable to initialize module ${1}." >&2
			fc_exit 2
		fi

		fc_array_append FC_INHERITED "${fn}"
	else
		echo "FATAL ERROR: unable to load module ${fn} as requested by ./configure." >&2
		fc_exit 2
	fi
}

# Synopsis: fc_inherit <module> [...]
# Inherit the functions from <module>.
fc_inherit() {
	local fn

	for fn in "${@}"; do
		if fc_array_has ${fn} ${FC_INHERITED}; then
			: # (module already loaded)
		else
			_fc_inherit "${fn}"
		fi
	done
}

# Synopsis: fc_version_ge <a> <b>
# Check whether version <a> is greater or equal than version <b>, and
# return true or false appropriately. Both <a> and <b> have to be
# simple version numbers, consisting of comma-separated integers.
fc_version_ge() {
	local ifs_save ret vera verb v
	ifs_save=${IFS}
	IFS=.
	vera=${1}
	ret=2

	set -- ${2}
	for v in ${vera}; do
		if [ ${#} -eq 0 ]; then
			# vera is longer, and previous components were equal
			ret=0
			break
		elif [ ${v} -lt ${1} ]; then
			# current component of vera is smaller
			ret=1
			break
		elif [ ${v} -gt ${1} ]; then
			# current component of vera is larger
			ret=0
			break
		fi
		shift
	done

	if [ ${ret} -eq 2 ]; then
		if [ ${#} -gt 0 ]; then
			# verb is longer, previous components were equal
			ret=1
		else
			# vera = verb
			ret=0
		fi
	fi
	
	IFS=${ifs_save}
	return ${ret}
}

# Synopsis: _fc_api_checkver
# Checks whether fastconf provides the requested version of API. Called
# after conf_init() so you may adjust FC_API_WANT there based on FC_API
# and FC_API_MIN if you want.
_fc_api_checkver() {
	if [ -z "${FC_API_WANT}" ]; then
		echo "IMPORTANT: please set FC_API_WANT to the expected fastconf API version" >&2
		echo "in your ./configure script (currently FC_API=${FC_API})." >&2
	else
		if ! fc_version_ge "${FC_API}" "${FC_API_WANT}"; then
			echo "ERROR: fastconf doesn't provide API ${FC_API_WANT} requested by ./configure" >&2
			echo "(current version: ${FC_API}). Please consider upgrading fastconf." >&2
			fc_exit 2
		elif ! fc_version_ge "${FC_API_WANT}" "${FC_API_MIN}"; then
			echo "ERROR: fastconf doesn't provide backwards compatibility to API ${FC_API_WANT}." >&2
			echo "Please consider upgrading the ./configure script to at least API ${FC_API_MIN}." >&2
			fc_exit 2
		fi
	fi
}

# Synopsis: fc_have <app> [<fallback-args> [...]]
# Portably check whether application <app> is available on the system.
# Please notice that this function is not guaranteed to work with
# builtins or functions, and it may call "${@}" if it is unable to find
# a non-invasive method of finding the app. If no <fallback-args> are
# specified, fc_have() defaults to '--version'.
fc_have() {
	if type type >/dev/null 2>&1; then
		type "${1}" >/dev/null 2>&1
	elif which which >/dev/null 2>&1; then
		which "${1}" >/dev/null 2>&1
	else
		[ ${#} -lt 2 ] && set -- "${1}" --version
		"${@}" >/dev/null 2>&1
		[ ${?} -ne 127 ]
	fi
}

# System checks support

# Synopsis: fc_def <name> [<val>]
# Output '#define <name> <val>'.
fc_def() {
	echo "#define ${1}${2+ ${2}}"
}

# Synopsis: fc_check <name> [<desc>]
# Check whether the check <name> succeeded and return either true
# or false. If <desc> is provided, print either "<desc> found"
# or "<desc> unavailable."
fc_check() {
	if [ -f "check-${1}" ]; then
		[ -n "${2}" ] && echo "${2} found." >&2
		return 0
	else
		[ -n "${2}" ] && echo "${2} unavailable." >&2
		return 1
	fi
}

# Callback: conf_check_results
# Called when './configure --create-config=*' is called. Should check
# the configure results (using fc_check) and define the appropriate
# macros for config.h file (using fc_def).

# Callback: conf_get_exports
# Called by './configure --create-config' and './configure --make'.
# Should check the configure results and export necessary macros for
# make (using fc_export).

# Synopsis: _fc_create_config <config-file>
# Call conf_check_results() to get the config.h file contents and write
# them into <config-file>. Afterwards, call conf_get_exports() to get
# the necessary make macros and append them to Makefile.
_fc_create_config() {
	_fc_call_exports check_results > "${1}"
	fc_export FC_EXPORTED 1 >> Makefile
	_fc_call_exports get_exports >> Makefile
}

# Makefile generation

# Synopsis: fc_export <name> <value>
# Write a variable/macro export for make. Can be used within
# conf_get_targets() and conf_get_exports().
fc_export() {
	echo "${1}=${2}"
}

# Synopsis: fc_set_target <target> <prereqs>
# Output a simple make target <target>, setting its prerequisities to
# <prereqs>.
fc_set_target() {
	echo "${1}: ${2}"

	fc_array_append FC_TARGETLIST "${1}"
}

# Synopsis: fc_add_subdir <subdir>
# Support descending into a subdirectory <subdir> within the default
# targets.
fc_add_subdir() {
	fc_array_append FC_SUBDIRS "${1}"
}

# Synopsis: _fc_build [<target>]
# Call make to build target <target> (or the default one if no target is
# passed), passing the necessary defines to make.
_fc_build() {
	local ifs_save
	ifs_save=${IFS}
	IFS='
'
	set -- "${1}" $(_fc_call_exports get_exports)
	IFS=${ifs_save}

	echo make "${@}" >&2
	make "${@}"
}

# Synopsis: _fc_setup_subdir_rules <target>
_fc_setup_subdir_rules() {
	local d

	for d in ${FC_SUBDIRS}; do
		printf '\t+[ ! -f "%s"/Makefile ] || { cd "%s" && make %s; }' ${d} ${d} ${1}
	done
}

# Callback: conf_get_targets
# Called by fc_setup_makefile() in order to get the complete target list
# for the Makefile. This should output targets for both the configure
# and build phases.

# Synopsis: fc_setup_makefile <out> [<in>]
# Create an actual Makefile in file <out>, appending the file <in>
# afterwards (if supplied).
fc_setup_makefile() {
	unset FC_TESTLIST FC_TESTLIST_SOURCES FC_OUTPUTLIST FC_TARGETLIST \
		FC_INSTALL FC_INSTALL_PREREQS FC_SUBDIRS

	cat > "${1}" <<_EOF_
# generated automatically by ./configure
# please modify ./configure${2+ ${2}} instead

DESTDIR =

PREFIX = ${PREFIX}
EXEC_PREFIX = ${EXEC_PREFIX}

BINDIR = ${BINDIR}
SBINDIR = ${SBINDIR}
LIBEXECDIR = ${LIBEXECDIR}
SYSCONFDIR = ${SYSCONFDIR}
LOCALSTATEDIR = ${LOCALSTATEDIR}
LIBDIR = ${LIBDIR}
INCLUDEDIR = ${INCLUDEDIR}
DATAROOTDIR = ${DATAROOTDIR}
DATADIR = ${DATADIR}
LOCALEDIR = ${LOCALEDIR}
MANDIR = ${MANDIR}
DOCDIR = ${DOCDIR}
HTMLDIR = ${HTMLDIR}

default: ${FC_CONFIG_H-all}
_EOF_

	if [ -n "${FC_CONFIG_H+1}" ]; then
		cat >> "${1}" <<_EOF_
	@+if [ -n "\$(FC_EXPORTED)" ]; then \$(MAKE) all; else ./configure --make=all; fi
	@+\$(MAKE) confclean
_EOF_
	fi

	_fc_call_exports get_targets >> "${1}"

	if [ -n "${FC_CONFIG_H+1}" ]; then
		cat >> "${1}" <<_EOF_

config:
	@rm -f ${FC_CONFIG_H}
	@+\$(MAKE) ${FC_CONFIG_H}
	@+\$(MAKE) confclean

${FC_CONFIG_H}:
	@echo "** MAKE CONFIG STARTING **" >&2
	@+\$(MAKE) confclean
	-+\$(MAKE) -k ${FC_TESTLIST}
	./configure --create-config=\$@
	@echo "** MAKE CONFIG FINISHED **" >&2

confclean:
	@rm -f ${FC_TESTLIST} ${FC_TESTLIST_SOURCES}

.PHONY: config confclean
_EOF_
	fi

	cat - ${2} >> "${1}" <<_EOF_

clean:
${FC_OUTPUTLIST+	rm -f ${FC_OUTPUTLIST}}
$(_fc_setup_subdir_rules clean)

distclean: clean ${FC_CONFIG_H+confclean}
	rm -f Makefile ${FC_CONFIG_H}
$(_fc_setup_subdir_rules distclean)

.PHONY: all clean default distclean ${FC_INSTALL+install} ${FC_TARGETLIST} 

all: ${FC_INSTALL_PREREQS}
$(_fc_setup_subdir_rules all)

${FC_INSTALL+install: default${FC_INSTALL}}
${FC_INSTALL+$(_fc_setup_subdir_rules install)}
_EOF_
	rm -f ${FC_CONFIG_H}
}

# INITIALIZATION RULES

# Callback: conf_init
# Obligatory. Called after loading fastconf but before any processing
# begins. Additional modules should be loaded here, using fc_inherit().
# Should return true; otherwise configure will be aborted.

_fc_inherit _shutils
if ! conf_init; then
	echo 'FATAL ERROR: conf_init() failed.' >&2
	fc_exit 2
fi
_fc_api_checkver
fc_inherit _cmdline
_fc_check_exports

_fc_cmdline_parse "${@}"

fc_setup_makefile Makefile ${FC_MAKEFILE_IN}
fc_exit 0
