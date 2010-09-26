#!/bin/false
# fastconf -- command-line parsing module
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod__cmdline_init() {
	# Clean up the environment for command-line parsing

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

	_fc_call_exports help && echo || :
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
				fc_exit 0
				;;
			--make=*)
				_fc_build "${1#--make=}"
				fc_exit ${?}
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
				fc_exit 0
				;;
			--version)
				echo "${PACKAGE} configure script, using fastconf ${FC_API}"
				fc_exit 0
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

	_fc_cmdline_default
	_fc_call_exports cmdline_parsed || :
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
