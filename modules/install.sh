#!/bin/false
# fastconf -- installation-related functions
# (c) 2010 Michał Górny
# Released under the terms of the 3-clause BSD license.

: ${FC_INSTALL_UMASK:=a+rx}
: ${FC_INSTALL_CHMOD:=a+r}
: ${FC_INSTALL_CHMOD_EXE:=a+rx}

fc_mod_install_init() {
	fc_export_functions \
		fc_mod_install_help \
		fc_mod_install_cmdline_parse \
		fc_mod_install_cmdline_parsed

	unset PREFIX EXEC_PREFIX \
		BINDIR SBINDIR LIBEXECDIR SYSCONFDIR \
		LOCALSTATEDIR \
		LIBDIR INCLUDEDIR DATAROOTDIR DATADIR \
		LOCALEDIR MANDIR DOCDIR HTMLDIR
}

fc_mod_install_help() {
	cat <<_EOF_
	--prefix=DIR		Prefix used to install arch-independent files
				(\${PREFIX}, default: /usr/local)
	--exec-prefix=DIR	Prefix used to install arch-dependent files
				(\${EXEC_PREFIX}, default: \${PREFIX})

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
}

fc_mod_install_cmdline_parse() {
	case "${1}" in
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
	esac
}

fc_mod_install_cmdline_parsed() {
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


