#!/bin/false
# fastconf -- file manipulations (patching) support
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_patch_init() {
	true
}

# Synopsis: fc_sed <in> <out> <sed-command> [...]
fc_sed() {
	local in out ec
	in=${1}
	out=${2}
	shift
	shift

	# Prepend each sed command with '-e' and quote it.
	ec=$(( ${#} * 2 ))
	while [ ${#} -lt ${ec} ]; do
		set -- "${@}" -e "\"${1}\""
		shift
	done

	printf '%s: %s\n\tsed %s $< > $@' \
		"${out}" "${in}" "${*}"

	_fc_append_output "${out}"
}
