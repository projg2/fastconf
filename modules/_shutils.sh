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
