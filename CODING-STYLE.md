fastconf -- coding style reference
==================================

Preface
-------

This reference describes the coding style rules and suggestions used
in fastconf and the bundled modules. They are _obligatory_ for main
fastconf code and the standard modules, and _suggested_ for external
modules and configure scripts.


General shell code policy
-------------------------

1. The shell code must be compliant with Single Unix Specification
	version 3, with the following remarks:
	
	1. Parts of the specification marked as 'XSI extensions' should not
		be used.

	2. `local` should be used to declare local variable list (without
		assignments), however the script must not assume they would have
		any effect.

		In other words, you should avoid using the same name for
		variables which are used in two functions in the same time. You
		should also remember to `unset` local variables explicitly
		whenever necessary.

			guess_something() {
				local i out ret
				unset out
				ret=1

				for i in "${@}"; do
					out=${out}$(somecommand "${i}")
					[ $? -eq 0 ] && ret=0
				done

				return ${ret}
			}

	3. due to the above assumption, `local` should not be used to
		localize special shell variables like `IFS` (the localization
		would be pointless).

		The correct way to handle `IFS` change is:

			myfunc() {
				local ifs_save
				ifs_save=${IFS}
				IFS=:
				# ...
				IFS=${ifs_save}
			}

2. Additional features of other shells (like bash or dash) can be used
	as long as the following conditions are met:

	1. The code provides a fallback mechanism for POSIX shell (like use
		of `type` in `fc_have()`) or implements an optional feature that
		is not strictly related to the configuration process (e.g. call
		backtrace).

	2. The code is able to correctly detect the feature support
		in the running shell with no probability of mistake (e.g.
		checking `${BASH_VERSION}` is not enough).

	3. The code performing the feature support detection doesn't result
		in visual output when used in a shell not supporting it.

	For example, if you wanted to use a bash array, you would use a code
	like that:

		array_using_func() {
			local arr

			if declare -a arr >/dev/null 2>&1; then
				: # the shell supports bash arrays
			else
				: # the shell doesn't support them
			fi
		}

3. If a shell script is supposed to be executed directly (i.e.
	the `configure` script), it should start with a shebang pointing
	at the POSIX shell implementation:

		#!/bin/sh

	If a shell script is supposed to be sourced within other script only
	(that is a case for `fastconf.sh` and fastconf modules), the shebang
	should point to the `false` implementation instead:

		#!/bin/false

4. The scripts should ensure proper handling of errors and ignoring
	the command return codes whenever necessary for the scripts to work
	with `set -e`. The failures should be ignored like the following:

		_fc_call_exports foo || :


Code style suggestions
----------------------

1. All nested code blocks (functions, `if..fi`, `for..done`) should be
	indented using a _single_ tabulator.

2. In compound statements like `if..fi` and `for..done`, the code start
	keyword (`then` or `do`) should be in the same line
	as the condition, separated by `; ` (a semicolon and a single
	space following it, no space before it).

3. In the `case..esac` conditional construct one indent should be used
	for the labels, and a second one for actual code. The labels and
	the compound terminators (`;;`) should be on a separate line.
	The last compound should not use the terminator.

		case ${foo} in
			0)
				:
				;;
			*)
				:
		esac

4. No attempts at code or comment alignment should be used. It is
	preferred to put comments on a separate line rather than inline with
	code.

5. All the comments and other text (especially output) should be wrapped
	at 72 characters (if possible). Code wrapping is optional.

6. When wrapping command invocations, the 'newline escape' (backslash)
	should be preceded by a single space, and the following code lines
	should be indented using a single tab.


Writing fastconf modules
------------------------

1. Each fastconf module should start with the following header:

		#!/bin/false
		# fastconf -- <short module description>
		# (c) <copyrights>
		# <license line>

	For example, the cc module header uses the following header:

		#!/bin/false
		# fastconf -- C compiler support
		# (c) 2010 Michał Górny
		# Released under the terms of the 3-clause BSD license.

2. Each fastconf module has to declare `fc_mod_<module-name>_init()`
	function returning true value. If the init is a no-op, it should
	look like:

		fc_mod_foo_init() {
			:
		}

	Otherwise, it should resemble the following scheme:

		fc_mod_foo_init() {
			fc_inherit bar
			fc_export_functions \
				fc_mod_foo_somefunc \
				fc_mod_foo_otherfunc
		}

3. If a fastconf module wishes to declare a handler for one of fastconf
	callbacks, the handler functions must be named
	`fc_mod_<module-name>-<callback-name>` and exported using
	`fc_export_functions()`. Other functions must not be passed to
	`fc_export_functions()`.

4. The suggested function order for fastconf modules is:

	1. The initialization function (`fc_mod_*_init()`),
	2. the callback functions (`fc_mod_*_*()`),
	3. other functions.


<!--
	(c) 2010 Michał Górny
	Released under the terms of the 3-clause BSD license.
	vim: set tw=72 syn=markdown :
-->
