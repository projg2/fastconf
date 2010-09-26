#!/bin/false
# fastconf -- installation-related functions
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

fc_mod_install_init() {
	:
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

	fc_array_append FC_INSTALL_PREREQS "${@}"

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

	fc_array_append FC_INSTALL_PREREQS "${3}"
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


