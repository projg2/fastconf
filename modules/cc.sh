#!/bin/false
# fastconf -- C compiler support
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_cc_init() {
	fc_inherit cc_common
	fc_export_functions \
		fc_mod_cc_help \
		fc_mod_cc_cmdline_parsed \
		fc_mod_cc_get_targets
}

fc_mod_cc_help() {
	cat <<_EOF_
	CC=<name>		C compiler command
	CFLAGS='<flag> ...'	C compiler flags

_EOF_
}

fc_mod_cc_cmdline_parsed() {
	# Sadly, we don't have any -cc prefixed with a host triplet.
	# Thus, we have to look for -gcc too.
	local ccnames cc

	[ -n "${CC}" ] && return

	if [ -z "${CC}" -a -n "${CHOST}" ]; then
		if fc_have "${CHOST}"-gcc; then
			CC=${CHOST}-gcc
		elif fc_have "${CHOST}"-cc; then
			CC=${CHOST}-cc
		else
			echo "WARNING: ${CHOST}-{gcc,cc} not found." >&2
		fi
	fi

	if [ -z "${CC}" ]; then
		if fc_have gcc; then
			CC=gcc
		elif fc_have cc; then
			CC=cc
		else
			echo "ERROR: unable to find any C compiler (neither gcc nor cc)." >&2
			fc_exit 1
		fi
	fi

	echo "Using guessed C compiler: ${CC}" >&2
}

fc_mod_cc_get_targets() {
	fc_export CC "${CC}"
	fc_export CFLAGS "${CFLAGS}"
}

# Synopsis: _fc_mkrule_code <name> <includes> <code>
# Output a Makefile rule creating a simple C program code using passed
# <includes> and <code>. The program would take the form of:
#	<includes>
#	int main(int argc, char *argv[]) { <code> }
# where <includes> and <code> can contain escapes and apostrophes have
# to be escaped.
_fc_cc_mkrule_code() {
	printf "%s.c:\n\t@printf '%%b%s { %%b }%s' '%s' '%s' > \$@\n" \
		"${1}" '\nint main(int argc, char *argv[])' '\n' "${2}" "${3}"
}

# Synopsis: _fc_mkcall_compile <infiles> [<cppflags>] [<append>]
_fc_cc_mkcall_compile() {
	printf '\t%s %s %s %s %s\n' \
		'$(CC) -c $(CFLAGS) $(CONF_CPPFLAGS) $(CPPFLAGS)' "${2}" \
		'-o $@' "${1}" "${3}"
}

# Synopsis: _fc_mkcall_link <infiles> [<cppflags>] [<libs>] [<ldflags>] [<append>]
_fc_cc_mkcall_link() {
	printf '\t%s %s %s %s %s %s %s %s\n' \
		'$(CC) $(CFLAGS) $(CONF_CPPFLAGS) $(CPPFLAGS)' "${2}" "${4}" \
		'$(CONF_LDFLAGS) $(LDFLAGS) -o $@' "${1}" \
		'$(CONF_LIBS) $(LIBS)' "${3}" "${5}"
}

# Synopsis: fc_cc_try_compile <name> <includes> <code> [<cppflags>]
# Output a Makefile rule trying to compile a test program <name>
# (without linking it), passing <cppflags> to the compiler.
# For the description of <includes> and <code> see _fc_mkrule_code().
fc_cc_try_compile() {
	local fn
	fn=check-${1}

	_fc_cc_mkrule_code "${fn}" "${2}" "${3}"
	echo "${fn}.o: ${fn}.c"
	_fc_cc_mkcall_compile '$<' "${4}" \
		"${FC_VERBOSE+>/dev/null 2>&1}"
	echo

	fc_array_append FC_TESTLIST "${fn}.o"
	fc_array_append FC_TESTLIST_SOURCES "${fn}.c"
}

# Synopsis: fc_cc_try_link <name> <includes> <code> [<cppflags>] [<libs>] [<ldflags>]
# Output a Makefile rule trying to link a test program <name>, passing
# <cppflags>, <ldflags> and <libs> to the compiler. For the description
# of <includes> and <code> see _fc_mkrule_code().
fc_cc_try_link() {
	local fn
	fn=check-${1}

	_fc_cc_mkrule_code "${fn}" "${2}" "${3}"
	echo "${fn}: ${fn}.c"
	_fc_cc_mkcall_link '$<' "${4}" "${5}" "${6}" \
		"${FC_VERBOSE+>/dev/null 2>&1}"
	echo

	fc_array_append FC_TESTLIST "${fn}"
	fc_array_append FC_TESTLIST_SOURCES "${fn}.c"
}

# Synopsis: fc_cc_compile <src> [<cppflags>]
# Output a Makefile rule ompiling a single source file <src> into object
# <src%.*>.o, passing <cppflags> to the compiler.
fc_cc_compile() {
	local out
	out=${1%.*}.o

	echo "${out}: ${1} ${FC_BUILD_PREREQS}"
	_fc_cc_mkcall_compile '$<' "${2}"
	echo

	fc_array_append FC_OUTPUTLIST "${out}"
}

# Synopsis: fc_cc_link <prog> <objects> [<cppflags>] [<libs>] [<ldflags>]
# Output a Makefile rule linking the <prog> executable from <objects>
# object list (whitespace-delimitered), passing <cppflags>, <ldflags>
# and <libs> to the compiler.
fc_cc_link() {
	echo "${1}: ${2} ${FC_BUILD_PREREQS}"
	_fc_cc_mkcall_link "${2}" "${3}" "${4}" "${5}"
	echo

	fc_array_append FC_OUTPUTLIST "${1}"
}

# Synopsis: fc_cc_build <prog> <sources> [<cppflags>] [<libs>] [<ldflags>]
# Output Makefile rules compiling <sources> into object files, and then
# linking them together as <prog>. <cppflags>, <ldflags> and <libs> will
# be passed to the compiler as appropriate.
fc_cc_build() {
	local f outf
	unset outf

	for f in ${2}; do
		fc_cc_compile ${f} "${3}"
		fc_array_append outf "${f%.*}.o"
	done
	fc_cc_link "${1}" "${outf}" "${3}" "${4}" "${5}"
}
