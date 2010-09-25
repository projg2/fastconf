#!/bin/false
# fastconf basic definitions file
# Do not call directly, source within the ./configure script instead.
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

FC_MODULE_PATH=./modules
FC_API=0
FC_API_MIN=0

# PART 0
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

: ${FC_INSTALL_UMASK:=a+rx}
: ${FC_INSTALL_CHMOD:=a+r}
: ${FC_INSTALL_CHMOD_EXE:=a+rx}

unset FC_EXPORTED_FUNCTIONS

# Synopsis: fc_export_functions <func> [...]
# Add the function <func> and the following functions to the exported
# function list. The functions have to resemble the conf_* naming scheme
# (for ./configure script) or fc_mod_* one (for modules).
fc_export_functions() {
	FC_EXPORTED_FUNCTIONS=${FC_EXPORTED_FUNCTIONS+${FC_EXPORTED_FUNCTIONS} }${*}
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
	local funcname f sf ret
	funcname=${1}
	ret=1
	shift

	for f in ${FC_EXPORTED_FUNCTIONS}; do
		sf=${f%_${funcname}}
		if [ ${sf} = conf -o \( ${sf#fc_mod_} != ${sf} -a ${sf} != ${f} \) ]; then
			${f} "${@}" && ret=0
		fi
	done

	return ${ret}
}

# Synopsis: fc_inherit <module> [...]
# Inherit the functions from <module>.
fc_inherit() {
	local fn

	for fn in "${@}"; do
		if fc_have fc_mod_${fn}_init; then
			: # (module already loaded)
		elif [ -f "${FC_MODULE_PATH}/${fn}.sh" ]; then
			. "${FC_MODULE_PATH}/${fn}.sh"

			if ! fc_mod_${fn}_init; then
				echo "FATAL ERROR: unable to initalize module ${fn}." >&2
				exit 2
			fi
		else
			echo "FATAL ERROR: unable to load module ${fn} as requested by ./configure." >&2
			exit 2
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
			exit 2
		elif ! fc_version_ge "${FC_API_WANT}" "${FC_API_MIN}"; then
			echo "ERROR: fastconf doesn't provide backwards compatibility to API ${FC_API_WANT}." >&2
			echo "Please consider upgrading the ./configure script to at least API ${FC_API_MIN}." >&2
			exit 2
		fi
	fi
}

fc_have() {
	type "${1}" >/dev/null 2>&1
}

# PART I
# command-line parsing

# Synopsis: _fc_cmdline_unset
# Cleans up the environment for a clean fc_cmdline_parse() call.
_fc_cmdline_unset() {
	unset PREFIX EXEC_PREFIX \
		BINDIR SBINDIR LIBEXECDIR SYSCONFDIR \
		LOCALSTATEDIR \
		LIBDIR INCLUDEDIR DATAROOTDIR DATADIR \
		LOCALEDIR MANDIR DOCDIR HTMLDIR \
		CBUILD CHOST CTARGET
}

# Callback: conf_help
# Optional. Called after printing the standard help message. Should
# print additional option descriptions to stdout, and return true.
# stderr is dropped. If conf_help() succeeds, _fc_cmdline_help() prints
# additional blank line afterwards.

# Synopsis: _fc_cmdline_help
# Print the help message for command-line options.
_fc_cmdline_help() {
	cat <<_EOF_
Synopsis:
	./configure [options]

Options:
	--prefix=DIR		Prefix used to install arch-independent files
				(\${PREFIX}, default: /usr/local)
	--exec-prefix=DIR	Prefix used to install arch-dependent files
				(\${EXEC_PREFIX}, default: \${PREFIX})

	--build=PLATFORM
	--host=PLATFORM
	--target=PLATFORM

	--bindir=DIR		Path to install user binaries
				(default: \${EXEC_PREFIX}/bin)
	--sbindir=DIR		Path to install system admin binaries
				(default: \${EXEC_PREFIX}/sbin)
	--libexecdir=DIR	Path to install program executables
				(default: \${EXEC_PREFIX}/libexec)
	--sysconfdir=DIR	Path to install read-only local data (config)
				(default: \${PREFIX}/etc)
	--localstatedir=DIR	Path to install writable local data
				(default: \${PREFIX}/var)
	--libdir=DIR		Path to install libraries
				(default: \${EXEC_PREFIX}/lib)
	--includedir=DIR	Path to install C header files
				(default: \${PREFIX}/include)
	--datarootdir=DIR	Path to install read-only system data
				(\${DATAROOTDIR}, default: \${PREFIX}/share)
	--datadir=DIR		Path to install read-only program data
				(default: \${DATAROOTDIR})
	--localedir=DIR		Path to install locale data
				(default: \${DATAROOTDIR}/locale)
	--mandir=DIR		Path to install manpages
				(default: \${DATAROOTDIR}/man)
	--infodir=DIR		Path to install GNU info docs
				(default: \${DATAROOTDIR}/info)
	--docdir=DIR		Path to install documentation (\${DOCDIR},
				 default: \${DATAROOTDIR}/doc/\${PACKAGE})
	--htmldir=DIR		Path to install HTML docs
				(default: \${DOCDIR})

_EOF_

	_fc_call_exports help && echo
}

# Callback: conf_arg_parse "${@}"
# Called by fc_cmdline_parse() for unknown options, passing
# the remaining command-line as the argument. This function should
# return 0 if no match occured or shift count otherwise
# (i.e. 1 + number of positional arguments for the particular option).

# Callback: conf_cmdline_parsed
# Called after command-line parsing is complete and all defaults were
# set.

# Synopsis: _fc_cmdline_parse "${@}"
# Parses the passed command-line arguments, preserving the original
# argv.
_fc_cmdline_parse() {
	local i

	while [ ${#} -gt 0 ]; do
		case "${1}" in
			--create-config=*)
				_fc_create_config "${1#--create-config=}"
				exit 0
				;;
			--make=*)
				_fc_build "${1#--make=}"
				exit ${?}
				;;
			--build=*)
				CBUILD=${1#--build=}
				;;
			--host=*)
				CHOST=${1#--host=}
				;;
			--target=*)
				CTARGET=${1#--target=}
				;;
			--prefix=*)
				PREFIX=${1#--prefix=}
				;;
			--exec-prefix=*)
				EXEC_PREFIX=${1#--exec-prefix=}
				;;
			--bindir=*)
				BINDIR=${1#--bindir=}
				;;
			--sbindir=*)
				SBINDIR=${1#--sbindir=}
				;;
			--libexecdir=*)
				LIBEXECDIR=${1#--libexecdir=}
				;;
			--sysconfdir=*)
				SYSCONFDIR=${1#--sysconfdir=}
				;;
			--localstatedir=*)
				LOCALSTATEDIR=${1#--localstatedir=}
				;;
			--libdir=*)
				LIBDIR=${1#--libdir=}
				;;
			--includedir=*)
				INCLUDEDIR=${1#--includedir=}
				;;
			--datarootdir=*)
				DATAROOTDIR=${1#--datarootdir=}
				;;
			--datadir=*)
				DATADIR=${1#--datadir=}
				;;
			--localedir=*)
				LOCALEDIR=${1#--localedir=}
				;;
			--mandir=*)
				MANDIR=${1#--mandir=}
				;;
			--infodir=*)
				INFODIR=${1#--infodir=}
				;;
			--docdir=*)
				DOCDIR=${1#--docdir=}
				;;
			--htmldir=*)
				HTMLDIR=${1#--htmldir=}
				;;
			--help)
				_fc_cmdline_help
				exit 0
				;;
			--version)
				echo "${PACKAGE} configure script, using fastconf ${FC_API}"
				exit 0
				;;
			*)
				if _fc_call_exports arg_parse "${@}"; then
					case "${1}" in
						-*)
							# autoconf lists more than a single option here if applicable
							# but it's easier for us to print them one-by-one
							# and we keep the form to satisfy portage's QA checks
							echo "configure: WARNING: unrecognized options: ${1}" >&2
							;;
						*=*)
							# ah, an assignment
							export "${1}"
							;;
						*)
							echo "configure: WARNING: unrecognized argument: ${1}" >&2
							;;
					esac
				else
					i=${?}

					while [ ${i} -gt 1 ]; do
						shift
						: $(( i -= 1 ))
					done
				fi
		esac

		shift
	done
}

# Synopsis: _fc_cmdline_default
# Set default paths for directories not matched by _fc_cmdline_parse().
_fc_cmdline_default() {
	: ${CBUILD=}
	: ${CHOST=${CBUILD}}
	: ${CTARGET=${CHOST}}

	: ${PREFIX=/usr/local}
	: ${EXEC_PREFIX=\$(PREFIX)}

	: ${BINDIR=\$(EXEC_PREFIX)/bin}
	: ${SBINDIR=\$(EXEC_PREFIX)/sbin}
	: ${LIBEXECDIR=\$(EXEC_PREFIX)/libexec}
	: ${SYSCONFDIR=\$(PREFIX)/etc}
	: ${LOCALSTATEDIR=\$(PREFIX)/var}
	: ${LIBDIR=\$(EXEC_PREFIX)/lib}
	: ${INCLUDEDIR=\$(PREFIX)/include}
	: ${DATAROOTDIR=\$(PREFIX)/share}
	: ${DATADIR=\$(DATAROOTDIR)}
	: ${LOCALEDIR=\$(DATAROOTDIR)/locale}
	: ${MANDIR=\$(DATAROOTDIR)/man}
	: ${INFODIR=\$(DATAROOTDIR)/info}
	: ${DOCDIR=\$(DATAROOTDIR)/doc/${PACKAGE}}
	: ${HTMLDIR=\$(DOCDIR)}
}

# PART II
# System checks support

# Synopsis: _fc_append_test <name>
_fc_append_test() {
	FC_TESTLIST=${FC_TESTLIST+${FC_TESTLIST} }${1}
}

# Synopsis: _fc_append_source <name.c>
_fc_append_source() {
	FC_TESTLIST_SOURCES=${FC_TESTLIST_SOURCES+${FC_TESTLIST_SOURCES} }${1}
}

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

# PART III
# Makefile generation

# Synopsis: fc_export <name> <value>
# Write a variable/macro export for make. Can be used within
# conf_get_targets() and conf_get_exports().
fc_export() {
	echo "${1}=${2}"
}

# Synopsis: _fc_append_output <name>
_fc_append_output() {
	FC_OUTPUTLIST=${FC_OUTPUTLIST+${FC_OUTPUTLIST} }${1}
}

# Synopsis: fc_set_target <target> <prereqs>
# Output a simple make target <target>, setting its prerequisities to
# <prereqs>.
fc_set_target() {
	echo "${1}: ${2}"

	FC_TARGETLIST=${FC_TARGETLIST+${FC_TARGETLIST} }${1}
}

# Synopsis: fc_add_subdir <subdir>
# Support descending into a subdirectory <subdir> within the default
# targets.
fc_add_subdir() {
	FC_SUBDIRS=${FC_SUBDIRS+${FC_SUBDIRS} }${1}
}

# Synopsis: fc_install_dir <dir>
# Setup creating <dir> along with parent directories, making them all
# world-readable.
_fc_install_dir() {
	FC_INSTALL="${FC_INSTALL}
	umask ${FC_INSTALL_UMASK}; mkdir -p \"\$(DESTDIR)${1}\""
}

# Synopsis: fc_install_chmod <mode> <dest> <files>
fc_install_chmod() {
	local dest mode i
	mode=${1}
	dest=${2}
	shift
	shift

	_fc_install_dir "${dest}"
	FC_INSTALL="${FC_INSTALL}
	cp ${@} \"\$(DESTDIR)${dest}\""

	FC_INSTALL_PREREQS=${FC_INSTALL_PREREQS+${FC_INSTALL_PREREQS} }${@}

	# Transform the array to contain basenames
	i=${#}
	while [ ${i} -gt 0 ]; do
		set -- "${@}" "$(basename "${1}")"
		shift
		: $(( i -= 1 ))
	done

	FC_INSTALL="${FC_INSTALL}
	cd \"\$(DESTDIR)${dest}\" && chmod ${mode} ${@}"
}

# Synopsis: fc_install_as_chmod <mode> <dest> <src> <newname>
fc_install_as_chmod() {
	_fc_install_dir "${2}"
	FC_INSTALL="${FC_INSTALL}
	cp \"${3}\" \"\$(DESTDIR)${2}/${4}\"
	cd \"\$(DESTDIR)${2}\" && chmod ${1} \"${4}\""

	FC_INSTALL_PREREQS=${FC_INSTALL_PREREQS+${FC_INSTALL_PREREQS} }${3}
}

# Synopsis: fc_install <dest> <files>
# Setup installing <files> into <dest>, creating parent directories if
# necessary and making them world-readable afterwards.
fc_install() {
	fc_install_chmod ${FC_INSTALL_CHMOD} "${@}"
}

# Synopsis: fc_install_exe <dest> <files>
# Setup installing <files> into <dest>, creating parent directories if
# necessary and making them world-executable afterwards.
fc_install_exe() {
	fc_install_chmod ${FC_INSTALL_CHMOD_EXE} "${@}"
}

# Synopsis: fc_install_as <dest> <src> <newname>
fc_install_as() {
	fc_install_as_chmod ${FC_INSTALL_CHMOD} "${@}"
}

# Synopsis: fc_install_exe_as <dest> <src> <newname>
fc_install_exe_as() {
	fc_install_as_chmod ${FC_INSTALL_CHMOD_EXE} "${@}"
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
if ! conf_init; then
	echo 'FATAL ERROR: conf_init() failed.' >&2
	exit 2
fi
_fc_api_checkver
_fc_check_exports

_fc_cmdline_unset
_fc_cmdline_parse "${@}"
_fc_cmdline_default

_fc_call_exports cmdline_parsed
fc_setup_makefile Makefile ${FC_MAKEFILE_IN}
exit 0
