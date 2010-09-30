#!/bin/false
# fastconf -- shell utilities and compat
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod__shutils_init() {
	:
}

# local is not guaranteed by POSIX, so redeclare it if necessary.
# Of course, our fake-local won't do anything special but will silence
# out 'command not found' errors.

_fc_local_test() {
	local testing >/dev/null 2>&1
}

_fc_local_test || eval 'local() { :; }'

# string manip

# Synopsis: fc_uc <str>
# Output uppercase version of <str>.
fc_uc() {
	printf '%s' "${1}" | tr '[:lower:]' '[:upper:]'
}

# Synopsis: fc_macro_clean <str>
# Output 'macro-clean' version of <str> (uppercase, no special chars).
fc_macro_clean() {
	printf '%s' "$(fc_uc "${1}")" | tr -s -C '[:alnum:]' '_'
}

# arrays

# Synopsis: fc_array_has <needle> <elem1> [...]
fc_array_has() {
	local n
	n=${1}
	shift

	while [ ${#} -gt 0 ]; do
		[ "${1}" = "${n}" ] && return 0
		shift
	done

	return 1
}

# Synopsis: fc_array_append <varname> <elem1> [...]
fc_array_append() {
	local varname
	varname=${1}
	shift

	eval "set -- \${${varname}} \"\${@}\"; ${varname}=\${*}"
}
