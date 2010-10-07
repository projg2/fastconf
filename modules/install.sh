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
		fc_mod_install_arg_parse \
		fc_mod_install_cmdline_parsed \
		fc_mod_install_get_targets

	unset PREFIX EXEC_PREFIX \
		BINDIR SBINDIR LIBEXECDIR SYSCONFDIR \
		LOCALSTATEDIR \
		LIBDIR INCLUDEDIR DATAROOTDIR DATADIR \
		LOCALEDIR MANDIR DOCDIR HTMLDIR \
		FC_INSTALLED_DIRS
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

fc_mod_install_arg_parse() {
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
		*)
			return 0
	esac

	return 1
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

fc_mod_install_get_targets() {
	cat <<_EOF_
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
_EOF_
}

# Synopsis: fc_install_dir [-k] [-m <mode>] [--] <dir>
# Setup creating <dir> along with parent directories, and setting their
# permissions to <mode> (or ${FC_INSTALL_UMASK} if not specified).
# If '-k' (or '--keep') option is specified, a dotfile will be installed
# in order to prevent a possible removal of an empty directory.
fc_install_dir() {
	local dirumask ifs_save keepdir

	dirumask=${FC_INSTALL_UMASK}
	keepdir=0
	while [ ${#} -gt 0 ]; do
		case "${1}" in
			--mode=*)
				dirumask=${1#--mode=}
				shift
				;;
			-m|--mode)
				if [ ${#} -lt 2 ]; then
					echo 'fc_install_dir(): -m or --mode has to be followed by a mode spec.' >&2
					return 1
				fi
				dirumask=${2}
				shift 2
				;;
			-k|--keep)
				keepdir=1
				shift
				;;
			--)
				shift
				break
				;;
			*)
				break
		esac
	done

	# Newline seems a pretty reasonable directory list sep -- make
	# probably wouldn't like it anyway.
	ifs_save=${IFS}
	IFS='
'

	if ! fc_array_has "${1}" ${FC_INSTALLED_DIRS}; then
		FC_INSTALL="${FC_INSTALL}
	umask ${dirumask}; mkdir -p \"\$(DESTDIR)${1}\""
		if [ ${keepdir} -eq 1 ]; then
			FC_INSTALL="${FC_INSTALL}
	umask ${FC_INSTALL_CHMOD}; touch \"\$(DESTDIR)${1}\"/.keep"
		fi
		fc_array_append FC_INSTALLED_DIRS "${1}"
	fi

	IFS=${ifs_save}
}

# Synopsis: _fc_install_common [options] [--] <destdir> [...]
# Parse common arguments to fc_install() and fc_install_as() and create
# parent directories if requested. Set mode to the expected file
# permissions, and return shift count.
_fc_install_common() {
	local dmode i no_mkdir

	mode=${FC_INSTALL_CHMOD}
	no_mkdir=0
	i=0
	unset dmode
	while [ ${#} -gt 0 ]; do
		case "${1}" in
			-x|--executable)
				mode=${FC_INSTALL_CHMOD_EXE}
				shift
				: $(( i += 1 ))
				;;
			--mode=*)
				mode=${1#--mode=}
				shift
				: $(( i += 1 ))
				;;
			-m|--mode)
				if [ ${#} -lt 2 ]; then
					echo 'fc_install(): -m or --mode has to be followed by a mode spec.' >&2
					return 1
				fi
				mode=${2}
				shift 2
				: $(( i += 2 ))
				;;
			--directory-mode=*)
				dmode=${1#--directory-mode=}
				shift
				: $(( i += 1 ))
				;;
			-d|--directory-mode)
				if [ ${#} -lt 2 ]; then
					echo 'fc_install(): -d or --directory-mode has to be followed by a mode spec.' >&2
					return 1
				fi
				dmode=${2}
				shift 2
				: $(( i += 2 ))
				;;
			--)
				shift
				: $(( i += 1 ))
				break
				;;
			*)
				break
		esac
	done

	if [ ${no_mkdir} -ne 1 ]; then
		fc_install_dir ${dmode+-m ${dmode}} -- "${1}"
	fi

	return ${i}
}

# Synopsis: fc_install [-x|-m <mode>] [-d <mode>] [--] <dest> <files>
# Install <files> in <dest>, creating the parent directories
# and setting permissions as necessary. If '-d <mode>' is passed,
# that permissions will be given to newly-created directories.
# For files, the following algorithm is used:
#	1) if '-m <mode>' is passed, <mode> will be used,
#	2) if '-x' is passed, files will be made world-executable,
#	3) if none of the above is passed, files will be world-readable.
fc_install() {
	local dest mode i
	_fc_install_common "${@}" || shift ${?}
	dest=${1}
	shift

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

# Synopsis: fc_install_as [-x|-m <mode>] [-d <mode>] [--] <dest> <src> <newname>
# Install <src> to <dest>, renaming it to <newname>. For option
# descriptions, please look at fc_install().
fc_install_as() {
	local mode
	_fc_install_common "${@}" || shift ${?}

	FC_INSTALL="${FC_INSTALL}
	cp \"${2}\" \"\$(DESTDIR)${1}/${3}\"
	cd \"\$(DESTDIR)${1}\" && chmod ${mode} \"${3}\""

	fc_array_append FC_INSTALL_PREREQS "${2}"
}

# Synopsis: fc_install_conf [-m <mode>] [-d <mode>] [--] <dest> <src> [<newname>] [<distname>]
# Install config file <src> to <dest>. If <newname> is specified,
# the file will be installed under the new name.
#
# If the file with the same exists in <dest> already, it won't be
# replaced. If it doesn't differ from the one being installed, nothing
# will happen. If it does, the new file will be installed as <distname>
# instead. If <distname> is not specified, <newname> (or <src>) with
# '.dist' suffix appended will be used.
fc_install_conf() {
	local mode dest distdest
	_fc_install_common "${@}" || shift ${?}

	dest="\$(DESTDIR)${1}/${3-${2}}"
	distdest="\$(DESTDIR)${1}/${4-${3-${2}}.dist}"

	FC_INSTALL="${FC_INSTALL}
	if ! [ -f \"${dest}\" ]; then \
		cp \"${2}\" \"${dest}\" && \
		chmod ${mode} \"${dest}\"; \
	elif ! cmp \"${2}\" \"${dest}\" >/dev/null 2>&1; then \
		echo \"* Installing ${2} as ${distdest} to avoid overwriting.\" >&2; \
		cp \"${2}\" \"${distdest}\" && \
		chmod ${mode} \"${distdest}\"; \
	else \
		:; \
	fi"
}

# Synopsis: fc_install_man <files> [...]
# Setup installing manpages <files> into appropriate subdirectories
# of $(MANDIR) based on their basenames.
fc_install_man() {
	local fn category

	while [ ${#} -gt 0 ]; do
		fn=$(basename "${1}")
		category=${fn##*.}

		if [ -z "${category}" ]; then
			echo "ERROR: unable to parse manpage name: ${fn}, skipping." >&2
		else
			fn=${fn%.${category}}
			# autotools use first character only
			# but man doesn't seem to like it
			category='$(MANDIR)'/man${category}

			fc_install -- "${category}" "${1}"
		fi
		shift
	done
}

# Synopsis: fc_install_exe <dest> <files>
# Setup installing <files> into <dest>, creating parent directories if
# necessary and making them world-executable afterwards.
fc_install_exe() {
	echo "WARNING: fc_install_exe is deprecated, please use fc_install -x instead." >&2
	fc_install -x -- "${@}"
}

# Synopsis: fc_install_exe_as <dest> <src> <newname>
fc_install_exe_as() {
	echo "WARNING: fc_install_exe_as is deprecated, please use fc_install_as -x instead." >&2
	fc_install_as -x -- "${@}"
}
