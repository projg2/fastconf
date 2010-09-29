#!/bin/false
# fastconf -- command-line parsing module
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod__cmdline_init() {
	# Clean up the environment for command-line parsing

	unset CBUILD CHOST CTARGET
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

Options and arguments:
	--help			Print this help message
	--version		Print program and fastconf version

	--verbose		Enable verbose configure checks
	--keep-temp		Don't remove tests after configuring

	--build=PLATFORM
	--host=PLATFORM
	--target=PLATFORM

_EOF_

	_fc_call_exports help || :
}

# Callback: conf_arg_parse "${@}"
# Called by fc_cmdline_parse() for unknown options, passing
# the remaining command-line as the argument. This function should
# return 0 if no match occured or shift count otherwise
# (i.e. 1 + number of positional arguments for the particular option).

# Synopsis: _fc_call_arg_parse <args>
# arg_parse callback uses reverse logic (shift count as return code, so
# we can't use _fc_call_exports() here.
_fc_call_arg_parse() {
	local f
	for f in ${FC_EXPORTED_FUNCTIONS}; do
		case ${f} in
			conf_arg_parse|fc_mod_*_arg_parse)
				${f} "${@}" || return ${?}
		esac
	done

	return 0
}

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
			--help)
				_fc_cmdline_help
				fc_exit 0
				;;
			--version)
				echo "${PACKAGE} configure script, using fastconf ${FC_API}"
				fc_exit 0
				;;
			--verbose)
				FC_VERBOSE=1
				;;
			--quiet)
				FC_VERBOSE=0
				;;
			--keep-temp)
				FC_KEEPTEMP=1
				;;
			--no-keep-temp)
				FC_KEEPTEMP=0
				;;
			*)
				if _fc_call_arg_parse "${@}"; then
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
}
