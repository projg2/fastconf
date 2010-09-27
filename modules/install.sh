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

# Synopsis: fc_install_dir [-m <mode>] [--] <dir>
# Setup creating <dir> along with parent directories, and setting their
# permissions to <mode> (or ${FC_INSTALL_UMASK} if not specified).
fc_install_dir() {
	local dirumask

	dirumask=${FC_INSTALL_UMASK}
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
			--)
				shift
				break
				;;
			*)
				break
		esac
	done

	FC_INSTALL="${FC_INSTALL}
	umask ${dirumask}; mkdir -p \"\$(DESTDIR)${1}\""
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
			-D|--no-mkdir)
				no_mkdir=1
				shift
				: $(( i += 1 ))
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

# Synopsis: fc_install_man <files> [...]
# Setup installing manpages <files> into appropriate subdirectories
# of $(MANDIR) based on their basenames.
fc_install_man() {
	local fn category categories

	unset categories
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

			if ! fc_array_has "${category}" ${categories}; then
				fc_install_dir -- "${category}"
				fc_array_append categories "${category}"
			fi
			fc_install -D -- "${category}" "${1}"
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
