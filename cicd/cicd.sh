#!/bin/bash
#  shellcheck disable=2001  ## 'See if you can use ${variable//search/replace} instead.' Complains about good uses of sed.
#  shellcheck disable=2016  ## 'Expressions don't expand in single quotes, use double quotes for that.' I know, and I often want an explicit '$'.
#  shellcheck disable=2034  ## 'variable appears unused.' Complains about valid use of variable indirection (e.g. later use of local -n var=$1)
#  shellcheck disable=2046  ## 'Quote to prevent word-splitting.' (OK for integers.)
#  shellcheck disable=2086  ## 'Double quote to prevent globbing and word splitting.' (OK for integers.)
#  shellcheck disable=2119  ## 'Use foo "$@" if function's $1 should mean script's $1.' Confusing and inapplicable.
#  shellcheck disable=2120  ## 'Foo references arguments, but none are ever passed.' Valid function argument overloading.
#  shellcheck disable=2128  ## 'Expanding an array without an index only gives the element in the index 0.' False hits on associative arrays.
#  shellcheck disable=2155  ## 'Declare and assign separately to avoid masking return values.' Cumbersome and unnecessary. For integers it's sometimes required to even come into existence for counters.
#  shellcheck disable=2162  ## 'read without -r will mangle backslashes.'
#  shellcheck disable=2178  ## 'Variable was used as an array but is now assigned a string.' False hits on associative arrays with e.g. 'local -n assocArray=$1'.
#  shellcheck disable=2181  ## 'Check exit code directly, not indirectly with $?.'
#  shellcheck disable=2317  ## 'Can't reach.' (I.e. an 'exit' is used for debugging - and makes an unusable visual mess.)
## shellcheck disable=2002  ## 'Useless use of cat.'
## shellcheck disable=2004  ## '$/${} is unnecessary on arithmetic variables.' Inappropriate complaining?
## shellcheck disable=2053  ## 'Quote the right-hand sid of = in [[ ]] to prevent glob matching.' Disable for Yoda Notation.
## shellcheck disable=2143  ## 'Use grep -q instead of echo | grep'

##	Purpose: Wrapper for build, test, copy to local for dogfood, push to github. Calls test.sh, no need to call that separately.
##	History: At bottom of this file. (Note: History for this is maintained outside of [or in addition to] git project.)

##	Copyright © 2022-2026 Jim Collier (ID: 1cv◂‡Vᛦ)
##	Licensed under the GNU General Public License v2.0 or later. Full text at:
##		https://spdx.org/licenses/GPL-2.0-or-later.html
##	SPDX-License-Identifier: GPL-2.0-or-later


#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Constants
if [[ -z "${doQuietly+x}" ]]; then

	## Settings (relative paths defined here will be verified and resolved later)
	declare    dirPath_Base="$(dirname "${BASH_SOURCE[0]}")/.."
	declare    dirPath_Source="${dirPath_Base}"
	declare    filePath_ExecToTestAndInstall="${dirPath_Base}/convert-base-v1b"
	declare    filePath_TestExec="${dirPath_Base}/cicd/test.sh"
	declare    gitAutomationScript="${dirPath_Base}/utility/n8git_backup-and-publish"
	declare -a preferredInstallPaths=("${HOME}/synced/0-0/common/exec/util/linux/bin"  "/usr/local/sbin/")  ## First one that exists, wins
	declare -i isCompileProject=0  ## 1: E.g. C++, Rust, Go, etc.  0: E.g. Python, Bash, etc.

	## Generic constants
	declare  -i doQuietly=0
	declare  -i doPromptToContinue=1
	declare -r  thisVersion="1.0.0-beta.1"         ## Put you script's semantic version here.
	declare -r  thisBuild="20260423-140709"
	declare -r  thisCopyrightYear="2026"           ## Put your copyright date here.
	declare -r  thisAuthor="Jim Collier"           ## Put your copyright name here.
	declare -ri atLeastOneArgRequired=0
	declare -ri doAsSudo=0
fi

#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Copyright, about, & syntax (minified)
fCopyright(){ { ((doQuietly)) || ((wasShown_Copyright)); } && return; wasShown_Copyright=1;
	fEcho_Clean ""
	#           X-------------------------------------------------------------------------------X
#	fEcho_Clean "${meName} v${thisVersion} build ${thisBuild},"  ## Don't show version info. Can confuse with the version of the product being built.
	fEcho_Clean "${meName}, Copyright © ${thisCopyrightYear} ${thisAuthor}."
	fEcho_Clean "Licensed under the GNU General Public License v2.0 or later. Full text at:"
	fEcho_Clean "  https://spdx.org/licenses/GPL-2.0-or-later.html"
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "" ;:;}
fAbout(){ { ((doQuietly)) || ((wasShown_About)); } && return; wasShown_About=1;
	fEcho_Clean ""
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "CI/CD and dogfood:"
	if ((isCompileProject)); then
		fEcho_Clean "  • Builds the program. If successful:"
		fEcho_Clean "  • Cross-compile more versions. If those succeed:"
	fi
	fEcho_Clean "  • Run automated tests. If tests pass:"
	fEcho_Clean "  • Update locally-installed version to what was just compiled for dogfood."
	fEcho_Clean "  • Run git automation script (e.g. commit and push)."
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "" ;:;}
fSyntax(){  { ((doQuietly)) || ((wasShown_Syntax)); } && return; wasShown_Syntax=1;
	fEcho_Clean ""
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "Arguments:"
	fEcho_Clean "  --quiet"
	fEcho_Clean "      [optional]: Be less verbose, and don't prompt user to continue."
	fEcho_Clean "  --help"
	fEcho_Clean "      [optional]: Shows copyright, about, and this syntax."
	fEcho_Clean "  --version"
	fEcho_Clean "      [optional]: Shows copyright and version."
	#           X-------------------------------------------------------------------------------X
	fEcho_Clean "" ;:;}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fMain(){

	## Generic constants
	local ogUSER="" ; fGetOgUserName ogUSER             ; readonly ogUSER
	local ogHOME="" ; fGetOgUserHome ogHOME "${ogUSER}" ; readonly ogHOME

	## Generic variables
	local -i wasShown_Copyright=0; local -i wasShown_About=0; wasShown_Syntax=0

	## Check for need to show help
	{ ((atLeastOneArgRequired)) && [[ -z "${1:-}${2:-}${3:-}${4:-}" ]]; } && { fCopyright; fAbout; fSyntax; return 1; }
	case " ${*,,} " in
		*" -h "*|*" --help "*)                 fCopyright; fAbout; fSyntax; return 0; ;;
		*" -v "*|*" --ver "*|*" --version "*)  fCopyright;                  return 0; ;;
		*" -q "*|*" --quiet "*)                doQuiet=1;                             ;;
	esac

	## Validate dependencies
	fMustBeInPath realpath
	fMustBeInPath trash

	## Arguments
	local  -a allArgsArr=()
	local -ri parseArgs_maxPositionalArgCount=1  ## Variable expected by fParseArgs()
	fParseArgs  "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}"
	readonly allArgsArr

	## Resolve paths
	fResolvePath  dirPath_Base                   "${dirPath_Base}"                   ; readonly dirPath_Base
	fResolvePath  dirPath_Source                 "${dirPath_Source}"                 ; readonly dirPath_Source
	fResolvePath  filePath_ExecToTestAndInstall  "${filePath_ExecToTestAndInstall}"  ; readonly filePath_ExecToTestAndInstall
	fResolvePath  filePath_TestExec              "${filePath_TestExec}"              ; readonly filePath_TestExec
	fResolvePath  gitAutomationScript            "${gitAutomationScript}"            ; readonly gitAutomationScript

	##DEBUG
	#echo "dirPath_Base .....................: '${dirPath_Base}'"
	#echo "dirPath_Source ...................: '${dirPath_Source}'"
	#echo "filePath_ExecToTestAndInstall ....: '${filePath_ExecToTestAndInstall}'"
	#echo "filePath_TestExec ................: '${filePath_TestExec}'"
	#echo "gitAutomationScript ..............: '${gitAutomationScript}'"
	#exit

	## Validate
	[[ -d "${meDir}"                ]]  ||  fThrowError "Path not found: '${meDir}'"
	[[ -d "${dirPath_Base}"         ]]  ||  fThrowError "Path not found: '${dirPath_Base}'"
	[[ -d "${dirPath_Source}"       ]]  ||  fThrowError "Path not found: '${dirPath_Source}'"
	[[ -f "${filePath_TestExec}"    ]]  ||  fThrowError "File not found: '${filePath_TestExec}'"
	[[ -f "${filePath_TestExec}"    ]]  ||  fThrowError "File not found: '${filePath_TestExec}'"
	[[ -n "${gitAutomationScript}"  ]]  ||  fThrowError "Git automation script not found where specified or in path: '${gitAutomationScript}'."

	## Prompt to continue
	if ((! doQuietly)); then
		fCopyright
		fAbout
		fEcho_Clean "Base directory ...............: ${dirPath_Base}"
		fEcho_Clean "Source directory .............: ${dirPath_Source}"
		if ((isCompileProject)); then
		fEcho_Clean "Executable to build etc. .....: ${filePath_ExecToTestAndInstall}"
		fi
		fEcho_Clean "Test script ..................: ${filePath_TestExec}"
		fEcho_Clean "Git commit and push script ...: ${gitAutomationScript}"
		fIntroPromptToContinue  ""
		fEcho_Clean
	fi

	####
	#### MAKEITSO
	####

	pushd "${dirPath_Base}" 1>/dev/null

	if ((isCompileProject)); then

		## make
		fEcho "$(date "+%Y%m%d-%H%M%S") make: Starting ..."
		make
		fEcho "$(date "+%Y%m%d-%H%M%S") Minimal execution test ..."
		"${filePath_ExecToTestAndInstall}"  --version
		sleep 1  ## Long enough to see version

		## Hide single exe
		[[ -f "${filePath_ExecToTestAndInstall}_staged" ]]  &&  trash "${filePath_ExecToTestAndInstall}_staged"
		mv "${filePath_ExecToTestAndInstall}"  "${filePath_ExecToTestAndInstall}_staged"

		## Make release (part of testing - if they don't cross-compile then there' a problem)
		fEcho
		fEcho "$(date "+%Y%m%d-%H%M%S") make release: Starting ..."
		make release
		fEcho_ResetBlankCounter

		##Unhide single executable for testing and local installation
		mv "${filePath_ExecToTestAndInstall}_staged"  "${filePath_ExecToTestAndInstall}"

	fi

	## Test
	fEcho "$(date "+%Y%m%d-%H%M%S") Test: Starting ..."
	"${filePath_TestExec}"
	fEcho_ResetBlankCounter

	popd 1>/dev/null

	## Install locally (dogfood it)
	for nextPath in "${preferredInstallPaths[@]}"; do
		if [[ -d "${nextPath}" ]]; then
			fEcho; fEcho "$(date "+%Y%m%d-%H%M%S") Installing locally to '${nextPath}' ..."
			if [[ "${nextPath}" == "${ogHOME}/"* ]]; then
				cp -a "${filePath_ExecToTestAndInstall}"  "${nextPath%%/}/"
			else
				cp -a "${filePath_ExecToTestAndInstall}"  "${nextPath%%/}/" 2>/dev/null ||  sudo cp -a "${filePath_ExecToTestAndInstall}"  "${nextPath%%/}/"
			fi
			fEcho; fEcho "ls \$(which '$(basename "${filePath_ExecToTestAndInstall}")'):"
			ls  -lA  --color=always  --human-readable  --time-style=+"%Y-%m-%d %H:%M:%S"  "$(which "$(basename "${filePath_ExecToTestAndInstall}")")"
			fEcho_Force
			break
		fi
	done

	## Git automation script (e.g. commit, push)
	"${gitAutomationScript}"

#	## Run fMain_Chained(), as sudo if necessary, with important variables [and/or fArgs_*] serialized.
#	((doAsSudo))  &&  fChainToFunc  'fMain_Chained'  "$(declare -p  doQuietly  ogUSER  ogHOME)"

	## Done; either fChainToFunc() -> fMain_Chained() returned, or this script run in a sudo subshell [running only fMain_Chained()] returned.
	((! doQuietly)) && { fEcho "${meName}: Done."; fEcho; }
:;}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fMain_Chained(){
	[[ -n "${1:-}" ]]  &&  eval "${1:-}"  ## Restore caller's serialized variables [or fArgs_*]. New scope is local to this function.
#	[[ -n "${2:-}" ]]  &&  eval "${2:-}"  ## Restore caller's fArgs_*. New scope is local to this function.
	((! doQuietly))  &&  fEcho_Clean

	## Revalidate
	[[   -z "${doQuietly}" ]]                && { fThrowError "Arg not set: doQuietly" ; return 1; }
	[[   -z "${ogUSER}" ]]                   && { fThrowError "Arg not set: ogUSER"    ; return 1; }
	[[   -z "${ogHOME}" ]]                   && { fThrowError "Arg not set: ogHOME"    ; return 1; }

:;}


#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fParseArgs(){

	## Look for stars "✶✶✶✶✶✶✶✶" for places to custom-modify unique instances of this function.

	## GENERIC (don't modify): Populate args array and string.
	## Note: Args are 1-based index, but the resulting array of args at the end is a normal 0-based index.
	local -r -i maxPracticalArgCount=50  ## In Bash we have 2MB of args, or somewhere around 10k by count. For readabality and performance, keep it MUCH lower, say ~20-99.
	local    -i totalArgCount=0
	local    -i switchCounter=0
	allArgsArr=()
	## Store the highest non-empty argument number.
	local -i i; i=0
	for ((i=1; i<=maxPracticalArgCount; i++)); do [[ -n "${!i:-}" ]] && totalArgCount=$i; done
	local -ri totalArgCount=$totalArgCount
	## Build args str and array, including empty args - up to the last non-empty arg.
	local thisStr=""
	for ((i=1; i<=totalArgCount; i++)); do
		thisStr="${!i}"
		thisStr="${thisStr//\"/″}"; thisStr="${thisStr//\'/′}"
		allArgsArr+=("${thisStr}")
	done

	## GENERIC: Variables for loop
	local    tmpStr=""
	local    currentArg=""
	local    lastSwitch=""
	local -i expectingSwitchParamForNextArg=0
	local -i positionalArgCounter=0

	## Process arguments
	for currentArg in "${allArgsArr[@]}"; do
		#fEcho_Clean "Debug: currentArg ........: '${currentArg}'"

		## Test if an option switch or not
		if [[ -n "$(echo "${currentArg}" | grep -P "^\-(\-?)[^\ \-]" 2>/dev/null || true)" ]]; then
			## It's an option (either unary or long-option, we don't know yet)
			#fEcho_Clean "Debug: option ............: '${currentArg}'"

			## Check if this was supposed to NOT be a unary switch (eg expecting a parameter after previous long-option)
			((expectingSwitchParamForNextArg)) && fThrowError "Expecting a long-option argument for '${lastSwitch}', instead got another option '${currentArg}'."
			switchCounter=$((switchCounter + 1))

			## Validate switches, and act on unary switches
			lastSwitchAsPassed="${currentArg}"
			tmpStr="${currentArg,,}"

			## Strip switch dashes off
			while [[ "${tmpStr}" == -* ]]; do tmpStr="${tmpStr#-}"; done
			lastSwitch="${tmpStr}" ## Remember lastSwitch

			case "${tmpStr}" in

			#	## ✶✶✶✶✶✶✶✶ PUT CUSTOM UNARY SWITCH TESTS AND PARENT BOOLEAN VARIABLE ASSIGNMENTS HERE
			#	"unary-switch")  booleanVariable=1  ;;

			#	## ✶✶✶✶✶✶✶✶ PUT TESTS FOR CUSTOM LONG-OPTION LOGIC THAT EXPECTS AN ARGUMENT TO FOLLOW, HERE
			#	"long-option-with-arg-to-follow") expectingSwitchParamForNextArg=1 ;;

				## ¯\_(ツ)_/¯
				*) fThrowError  "Unexpected option in this context: '${currentArg}'."  ;;

			esac
		else
			## It's not an option switch; could be a long-option argument, or a positional arg

			if ((expectingSwitchParamForNextArg)); then :
				## Now we know to expecting an long-option argument
				#fEcho_Clean "Debug: arg for long-option: '${lastSwitch}': '${currentArg}'"

			#	## ✶✶✶✶✶✶✶✶ PUT CUSTOM LONG-OPTION ARGUMENT TESTS AND PARENT VARIABLE ASSIGNMENTS HERE
			#	case "${lastSwitch,,}" in
			#		"long-option-with-arg-to-follow") someParentVariable="${currentArg}" ;;
			#		*)                                fThrowError "Unkown option: '${lastSwitchAsPassed}', current parameter: '${currentArg}'." ;;  ## A redundant check.
			#	esac
			#	expectingSwitchParamForNextArg=0

			else
				## Well it must be a positional arg then.
				positionalArgCounter=$((positionalArgCounter + 1))
				((positionalArgCounter > parseArgs_maxPositionalArgCount))  && fThrowError "Too many positional arguments: ${positionalArgCounter}, for max of ${parseArgs_maxPositionalArgCount}."
				#fEcho_Clean "Debug: positional arg #${positionalArgCounter}: '${currentArg}'"

				## ✶✶✶✶✶✶✶✶ PUT CUSTOM POSITIONAL ARG LOGIC HERE (only use one of the following methods, delete the other)

				## Assign parent variables; Method 1: argument counter (less flexible but best for simple input)
				case $positionalArgCounter in
					1) stringArg="${currentArg}"      ;;
					2) arg_intArg="${currentArg}" ;;
					*) fThrowError "Unexpected positional argument # ${positionalArgCounter}: '${currentArg}'." ;;
				esac

			fi
		fi
	done
	((expectingSwitchParamForNextArg)) && fThrowError "Never received a parameter for switch '--${lastSwitch}'."

:;}  ## 'true' has to be the last thing or this function errors [the joys of the mysterious 'set -e'].


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fCleanup(){
	if ((! doQuietly)); then
		fEcho_Clean
	fi
}








#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Generic functions
fResolvePath(){
	## First looks at specified raw path. Next, same path but relative to this script. Next, in $PATH for an executable. Next, in this script's path, + /lib, /include, then /includes.
	local -n parentVarName_ResolvedPath_t4rej=${1:-}  ; shift || true  ## Parent variable to store fully resolved path in.
	local    nameOrPath="${1:-}"                      ; shift || true  ## File or folder path (relative or absolute). If an executable file, can be just a name to search in $PATH, to fully resolve.
	[[   -z "${nameOrPath}" ]]  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): No path specified to resolve.\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	local -r mePath_t4rfg="$(dirname "${BASH_SOURCE[0]}")"
	local -i isNopathObject=0 ; [[ "${nameOrPath}" == "$(basename "${nameOrPath}")" ]] && isNopathObject=1 ; readonly isNopathObject
	local    testPath="${nameOrPath}"
	  [[ ! -e "${testPath}"   ]]                           &&  testPath="${mePath_t4rfg}/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject)); }  &&  testPath="$(which "${nameOrPath}" 2>/dev/null || true)"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject)); }  &&  testPath="${mePath_t4rfg}/lib/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject)); }  &&  testPath="${mePath_t4rfg}/include/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject)); }  &&  testPath="${mePath_t4rfg}/includes/${nameOrPath}"
	  [[ ! -e "${testPath}"   ]]                           &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔc].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	testPath="$(realpath -e "${testPath}" 2>/dev/null || true)"
	## Last check to fail on
	{ [[ -n "${testPath}" ]] && [[ -e "${testPath}" ]]; } || { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔs].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	## Success
	parentVarName_ResolvedPath_t4rej="${testPath}"
}
fGetOgUserName(){
	local -n varName_s74rg=$1  ## Arg <REQUIRED>: Variable reference for result.
	local    retVal=""
	varName_s74rg=""
	retVal="${USER}"                         ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "root" ]]; } && { varName_s74rg="${retVal}"; return 0; }
	retVal="${SUDO_USER}"                    ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "root" ]]; } && { varName_s74rg="${retVal}"; return 0; }
	retVal="$(whoami  2>/dev/null || true)"  ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "root" ]]; } && { varName_s74rg="${retVal}"; return 0; }
	retVal="$(logname 2>/dev/null || true)"  ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "root" ]]; } && { varName_s74rg="${retVal}"; return 0; }
	retVal="${USER}"                         ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "root" ]]; } && { varName_s74rg="${retVal}"; return 0; }
	retVal="${USER}"                         ;   [[ -n "${retVal}" ]]                                     && { varName_s74rg="${retVal}"; return 0; }
	retVal="$(whoami  2>/dev/null || true)"  ;   [[ -n "${retVal}" ]]                                     && { varName_s74rg="${retVal}"; return 0; }
	[[ -z "${retVal}" ]] && fThrowError  "Could not figure out username. This could be a bug [¢Яēᛏ]."  "${FUNCNAME[0]}" ;:;}
fGetOgUserHome(){
	local -n varName_s74rm=$1            ## Arg <REQUIRED>: Variable reference for result.
	local    userName_s74rm="${2:-}"     ## Arg [optional]: Username. If blank will use fGetOguserName().
	local    retVal=""
	varName_s74rm=""
	retVal="${HOME}"                                                                                       ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "/root" ]] && [[ -d "${retVal}" ]]; } && { varName_s74rm="${retVal}"; return 0; }
	[[ -z "${userName_s74rm}" ]]  &&  fGetOgUserName userName_s74rm
	retVal="$(eval echo "~${userName_s74rm}")"                                                             ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "/root" ]] && [[ -d "${retVal}" ]]; } && { varName_s74rm="${retVal}"; return 0; }
	retVal="$(getent passwd "${userName_s74rm:-${SUDO_USER:-${USER}}}" | cut -d: -f6 2>/dev/null || true)" ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "/root" ]] && [[ -d "${retVal}" ]]; } && { varName_s74rm="${retVal}"; return 0; }
	retVal="/home/${userName_s74rm}"                                                                       ; { [[ -n "${retVal}" ]] && [[ "${retVal,,}" != "/root" ]] && [[ -d "${retVal}" ]]; } && { varName_s74rm="${retVal}"; return 0; }
	retVal="${HOME}"                                                                                       ; { [[ -n "${retVal}" ]] && [[ -d "${retVal}" ]]; }                                   && { varName_s74rm="${retVal}"; return 0; }
	[[   -z "${retVal}" ]]  &&  fThrowError  "Could not figure out user's home directory. This could be a bug [¢Яēᛏ]."
	[[ ! -d "${retVal}" ]]  &&  fThrowError  "Calculated home directory doesn't exist: '${retVal}'. This could be a bug [£⍤ㅍᛦ]." ;:;}
fChainToFunc(){
	[[ -z "${UID}" ]]  &&  { fThrowError "Can't determine user ID via \$UID."; return 2; }
	local -r chainFuncName="${1}"   #....: Function name to chain to, either directly or by relaunching. Recommended to be "fMain_Chained".
	## "${2}" could be anything (or nothing) that fMain() and fMain_Chained() agree to; for example could just be script arg 1; or serialized constants, variables, arrays, and/or associative arrays from fMain(), that fMain_Chained() will deserialize. E.g.: "$(declare -p ogUSER  ogHOME)".
	## "${3}" could be nothing, script arg 2, or say serialized args [e.g. "$(declare -p arg1  arg2)"], or from "$(fArgs_Serialize)". Whatever fMain() and fMain_Chained() agree to.
	## "${4}" ... "${33}" could be ignored, or passed as script args 3 to 32.
	if [[ "${UID}" == "0" ]] || ((! doAsSudo)); then
		## Either we're currently running as root, or don't care (e.g. don't necessarily need to).
		## If currently running as root, it was by one of at least three options:
		##   1) This was lauched directly by user with sudo, or
		##   2) User is logged in as root, or
		##   3) This script launched recursively with sudo by the 'else' block below.
		## Whatever the case, now's the time to chain directly to ${chainFuncName}.
		$chainFuncName  "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}" "${33:-}"
	else
		## This case is [[ "${UID}" != "0" ]] && ((doAsSudo)). Which means we need to relaunch the whole script (in a subshell) as sudo.
		sudo echo "[ Relaunching as sudo ... ]"
		sudo "${mePath}"  "${relaunch_Key_sudo}"  "${chainFuncName}"  "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}" "${33:-}"
	fi; }
fDoesDirHaveContents(){
	[[   -z "${1}" ]]  &&  fThrowError  "No directory specified as arg 1."  "fDoesDirHaveContents"
	[[ ! -d "${1}" ]]                                     && return 1
	[[   -z "$(ls -1A "${1%%/}/" 2>/dev/null || true)" ]] && return 1
	return 0; }
fBuildQuotedParams(){
	local -n varName_1mtkp9p=$1 ; shift || true
	local -i maxIdx=0
	for i in {1..32}; do [[ -n "${!i}" ]] && maxIdx=$i; done
	for i in $(seq 1 $maxIdx); do ((i > 1)) && varName_1mtkp9p="${varName_1mtkp9p}  "; varName_1mtkp9p="${varName_1mtkp9p}\"${!i}\""; done; }
fRunGUI(){ #( (nohup "$*" &>/dev/null) & disown);
	local -r toExec="${1}" ; shift || true
	local quotedParams=""; fBuildQuotedParams  quotedParams   "${1}"  "${2}"  "${3}"  "${4}"  "${5}"  "${6}"  "${7}"  "${8}"  "${9}"  "${10}"  "${11}"  "${12}"  "${13}"  "${14}"  "${15}"  "${16}"  "${17}"  "${18}"  "${19}"  "${20}"  "${21}"  "${22}"  "${23}"  "${24}"  "${25}"  "${26}"  "${27}"  "${28}"  "${29}"  "${30}"  "${31}"  "${32}"
	( (eval "'${toExec}'  ${quotedParams}  &>/dev/null") & disown ) &>/dev/null; }
fRunGuiAsSudo(){
	local -r toExec="${1:-}"  ## Only used for testing validity. When executed, it's just another "parameter".
	[[ -z "${toExec}" ]]                                                                &&  { echo -e "\nError in '$(basename "${0}").${FUNCNAME[0]}.()': No GUI executable specified to run. \n"                          ; exit 1; }
	{ [[ ! -x "${toExec}" ]] && [[ -z "$(which "${toExec}" 2>/dev/null || true)" ]]; }  &&  { echo -e "\nError in '$(basename "${0}").${FUNCNAME[0]}.()': Cannot find executable explicitly or in \$PATH: '${toExec}'. \n" ; exit 1; }
	local quotedParams=""; fBuildQuotedParams  quotedParams   "${1}"  "${2}"  "${3}"  "${4}"  "${5}"  "${6}"  "${7}"  "${8}"  "${9}"  "${10}"  "${11}"  "${12}"  "${13}"  "${14}"  "${15}"  "${16}"  "${17}"  "${18}"  "${19}"  "${20}"  "${21}"  "${22}"  "${23}"  "${24}"  "${25}"  "${26}"  "${27}"  "${28}"  "${29}"  "${30}"  "${31}"  "${32}"
	sudo true; ( (eval "sudo  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/0/bus XDG_RUNTIME_DIR=/run/user/0  ${quotedParams}  &>/dev/null") & disown ) &>/dev/null; }
fMustBeInPath(){
	##	Unit tests passed on: 20250704.
	local -r programToCheckForInPath="${1:-}"
	if [[ -z "${programToCheckForInPath}" ]]; then
		fThrowError "Not program specified."  "${FUNCNAME[0]}"; return 1
	elif [[ -z "$(which ${programToCheckForInPath} 2>/dev/null || true)" ]]; then
		fThrowError "Not found in path: ${programToCheckForInPath}"; return 1
	fi ;:;}
fAppendStr(){
	##	Unit tests passed on: 20250704.
	[[ -v varName_s74nj ]] && fThrowError "The first [and only] argument must be a parent-scoped variable, by-reference, to receive the this function's return value."
	local -n varName_s74nj=$1                        ## Arg <REQUIRED>: Variable reference that contains the string that will be modified in-place.
	local -r appendFirstIfExistingNotEmpty="${2:-}"  ## Arg [optional]: String to append between contents in $varName_s74nj if not empty, and $appendStr.
	local -r appendStr="${3:-}"                      ## Arg [optional]: String to append at end.
	[[ -n "${varName_s74nj:-}" ]] && varName_s74nj="${varName_s74nj}${appendFirstIfExistingNotEmpty}"
	varName_s74nj="${varName_s74nj:-}${appendStr}" ;:;}
fIntroPromptToContinue(){
	{ ((doQuietly)) || ((! doPromptToContinue)); } && return 0
	local -r extraInfoString="${1:-}"
	{ fEcho_Clean; fCopyright; fAbout; fEcho_Clean; }
	[[ -n "${extraInfoString}" ]]  &&  { fEcho_Clean; fEcho_Clean "${extraInfoString}"; }
	fPromptYN "Continue? (y|n): "  ||  { fEcho "User aborted."; return 1; }; }
fPromptYN(){
	((doQuietly)) && return 0
	local promptStr="${1:-}"
	[[ -z "${promptStr}" ]] && promptStr="Continue? (y|n): "
	read -r -p "${promptStr}" userAnswer
	fEcho_ResetBlankCounter
	{ [[ "${userAnswer,,}" == "y" ]] && return 0; } || return 1; }
fPressAnyKeyToContinue(){
	((doQuietly)) && return 0
	local promptStr="${1:-}"
	[[ -z "${promptStr}" ]] && promptStr="Press any key to continue ..."
	read -n 1 -s -p "${promptStr}" userAnswer
	fEcho_Clean_Force
	}
declare -i _wasLastEchoBlank=0
declare -i _isEchoInRawInlineMode=0
fEcho_ResetBlankCounter()     { _wasLastEchoBlank=0;      }
fEcho_WasLastEchoBlank_Set()  { { [[ "${1}" == "1" ]]  &&  _wasLastEchoBlank=1; }  ||  _wasLastEchoBlank=0;  }
fEcho_WasLastEchoBlank_Get()  { { ((_wasLastEchoBlank > 0))  &&  return 0; }  ||  return 1; }
fEcho_IsInRawInlineMode_Set() { { [[ "${1}" == "1" ]]  &&  _isEchoInRawInlineMode=1; }  ||  _isEchoInRawInlineMode=1; }  ## Script it telling fEcho* that something is going to be echoing to the screen in non-linefeed mode without its knowledge. (E.g. "echo -n 'something: '".)
fEcho_IsInRawInlineMode_Get() { { ((_isEchoInRawInlineMode))  &&  return 0; }  ||  return 1; }
fEcho_Clean(){
	((_isEchoInRawInlineMode))  &&  { echo; _wasLastEchoBlank=0; _isEchoInRawInlineMode=0; }
	if [[ -n "${1:-}" ]]; then echo -e "$*"; _wasLastEchoBlank=0; elif [[ $_wasLastEchoBlank -eq 0 ]]; then echo; _wasLastEchoBlank=1; fi; }
fEcho()                   { if [[ -n "$*" ]]; then fEcho_Clean "[ $* ]"; else fEcho_Clean ""; fi; }
fEcho_Force()             { fEcho_ResetBlankCounter; fEcho "$*";       }
fEcho_Clean_Force()       { fEcho_ResetBlankCounter; fEcho_Clean "$*"; }

#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Error-handling
declare -i _wasCleanupRun=0  ## Managed internally by this suite.
declare -i _doExitOnThrow=0    ## Managed internally by this suite.
declare -i _ErrVal=0         ## Set by this suite, but managed by calling functions. Think of it as an extended '$?' that doesn't immediately clear.
_fSingleExitPoint(){
	local -r signal="${1:-}"
	local -r lineNum="${2:-}"
	local -r exitCode="${3:-}"
	local -r errMsg="${4:-}"
	local -r errCommand="$BASH_COMMAND"
	_ErrVal=$exitCode
	if [[ "${signal}" == "INT" ]]; then
		fEcho_Force
		echo "User interrupted." >&2
		fEcho_ResetBlankCounter
		fCleanup  ## User cleanup
		exit 1
	elif [[ "${exitCode}" != "0" ]] && [[ "${exitCode}" != "1" ]]; then  ## Clunky string compare is less likely to fail than integer
		fEcho_Clean
		echo -e "Signal .....: '${signal}'"      >&2
		echo -e "Err# .......: '${exitCode}'"    >&2
	#	echo -e "Message ....: '${errMsg}'"      >&2
		echo -e "At line# ...: '${lineNum}'"     >&2
		echo -e "Command# ...: '${errCommand}'"  >&2
		fEcho_Clean_Force
		fCleanup  ## User cleanup
	else
		fCleanup  ## User cleanup
	fi ;}
_fTrap_Exit(){
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		_fSingleExitPoint "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}"
	fi ;}
_fTrap_Error(){
	if [[ "${_wasCleanupRun}" == "0" ]]; then  ## String compare is less to fail than integer
		_wasCleanupRun=1
		fEcho_ResetBlankCounter
		_fSingleExitPoint "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}"
	fi ;}
_fTrap_Error_Ignore(){ _ErrVal=1; true;  return 0; }
_fTrap_Error_Soft(){   _ErrVal=1; false; return 1; }
fThrowError(){
	local errMsg="${1:-}"         ; [[ -z "${errMsg}"      ]] && errMsg="An error occurred."
	local meNameLocal="${meName}" ; [[ -n "${meNameLocal}" ]] && errMsg="${meNameLocal}: ${errMsg}"
	local callStack=""
	for (( i = 1; i < ${#FUNCNAME[@]}; i++ )); do
		[[ "${FUNCNAME[i]}" =~ main|source ]] && continue
		[[ -n "${callStack}" ]] && callStack="${callStack}, "; callStack="${callStack}${FUNCNAME[i]}()"
	done
	[[ -n "${callStack}" ]] && callStack="Reverse call stack: ${callStack}"
	fEcho_Clean; echo -e "${errMsg}\n${callStack}" >&2; fEcho_ResetBlankCounter
	_ErrVal=1
	{ ((_doExitOnThrow)) && exit 1; } || return 1; }
fDefineTrap_Error_Fatal(){        :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error         ERR    ${LINENO}  $?  $_' ERR; set -e; } ## Standard; exits script on any caught error; but 'set -e' has known inconsistencies catching or ignoring errors.
fDefineTrap_Error_ExitOnThrow(){  :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error         ERR    ${LINENO}  $?  $_' ERR; set +e; } ## Only exits script on fThrowError().
fDefineTrap_Error_Soft(){         :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error_Soft    ERR    ${LINENO}  $?  $_' ERR; set -e; } ## Returns error code of 1 on error.
fDefineTrap_Error_Ignore(){       :; _ErrVal=0; _doExitOnThrow=0; trap '_fTrap_Error_Ignore  ERR    ${LINENO}  $?  $_' ERR; set +e; } ## Eats errors and returns true.
fDefineTrap_Error_Fatal
trap '_fTrap_Error SIGHUP  ${LINENO} $? $_' SIGHUP
trap '_fTrap_Error SIGINT  ${LINENO} $? $_' SIGINT    ## CTRL+C
trap '_fTrap_Error SIGTERM ${LINENO} $? $_' SIGTERM
trap '_fTrap_Exit  EXIT    ${LINENO} $? $_' EXIT
trap '_fTrap_Exit  INT     ${LINENO} $? $_' INT
trap '_fTrap_Exit  TERM    ${LINENO} $? $_' TERM


## Bash environment settings (comment out what you don't want)
 set -u  #..................: Require variable declaration. Stronger than mere linting. But can struggle if functions are in sourced files.
 set -e  #..................: Exit on errors. This is inconsistent (made a little better with settings below), so eventually may move to 'set +e' (which is more constant work and mental overhead).
 set -E  #..................: Propagate ERR trap settings into functions, command substitutions, and subshells.
 set   -o pipefail  #.......: Make sure all stages of piped commands also fail the same.
 shopt -s inherit_errexit  #: Propagate 'set -e' ........ into functions, command substitutions, and subshells. Will fail on Bash <4.4.
 shopt -s dotglob  #........: Include usually-hidden 'dotfiles' in '*' glob operations - usually desired.
 shopt -s globstar  #.......: ** matches more stuff including recursion.

## Check if sourced
declare -i isSourced; { (return 0 2>/dev/null) && isSourced=1; } || isSourced=0

## Common constants but detect if already set
if [[ -z "${serialDT+x}"     ]]; then
	declare -r serialDT="$(date "+%Y%m%d-%H%M%S")"
	declare -r mePath="$(realpath -e "${BASH_SOURCE[0]}")"
	declare -r meName="$(basename "${mePath}")"
	declare -r meDir="$(dirname "${mePath}")"
	declare -r relaunch_Key_sudo="${meName}_relaunch_sudo_4KQDYluNbzLQHwMwsWxgdk"  ## This isn't for 'security' or uniqueness. It just needs to be an exceptionally unlikely user argument.
fi

## Pass control to either fMain, or chained function.
if [[ "${1:-}" == "${relaunch_Key_sudo}" ]]; then
	[[ -z "${2:-}" ]]                     &&  fThrowError "A valid relaunch key was passed as arg1, but no function name was passed as arg2."
	declare -f "${2:-}" > /dev/null 2>&1  ||  fThrowError "The function name passed as arg2 isn't defined in this environment: '${2:-}'."
	## Invoke function specified by arg2
	${2:-} "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}" "${33:-}" "${34:-}"
else
	## Invoke main
	fMain  "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}" "${8:-}" "${9:-}" "${10:-}" "${11:-}" "${12:-}" "${13:-}" "${14:-}" "${15:-}" "${16:-}" "${17:-}" "${18:-}" "${19:-}" "${20:-}" "${21:-}" "${22:-}" "${23:-}" "${24:-}" "${25:-}" "${26:-}" "${27:-}" "${28:-}" "${29:-}" "${30:-}" "${31:-}" "${32:-}"
fi




##	Script history:
##		- 20260420 JC: Created.
##		- 20260421 JC: Finished.
##		- 20260422-23 JC: Copied and updated for convert-base-v1b.
