#!/bin/bash

# shellcheck disable=1090
# shellcheck disable=1091
# shellcheck disable=2001  ## Complaining about use of sed istead of bash search & replace.
# shellcheck disable=2002  ## Useless use of cat. This works well though and I don't want to break it for the sake of syntax purity.
# shellcheck disable=2004  ## Inappropriate complaining of "$/${} is unnecessary on arithmetic variables."
# shellcheck disable=2034  ## Unused variables.
# shellcheck disable=2119  ## Disable confusing and inapplicable warning about function's $1 meaning script's $1.
# shellcheck disable=2120  ## OK with declaring variables that accept arguments, without calling with arguments (this is 'overloading').
# shellcheck disable=2143  ## Used grep -q instead of echo | grep
# shellcheck disable=2154
# shellcheck disable=2155  ## Disable check to 'Declare and assign separately to avoid masking return values'.
# shellcheck disable=2162
# shellcheck disable=2181
# shellcheck disable=2207
# shellcheck disable=2317  ## Can't reach


##	Purpose:
##		- CI/CD-friendly test harness that passes or fails.
##		- Tests random output and round-trips through v2 to make sure the initial output was correct (at least if v2 is also correct).
##		- This is NOT part of cicd script, as it's not a requirement to have v2 installed.
##	History: At bottom of this file. (Note: History for this is maintained outside of [or in addition to] git project.)

##	Copyright
##		Copyright © 2026 Jim Collier (ID: 1cv◂‡Vᛦ)
##		Licensed under the GNU General Public License v2.0 or later. Full text at:
##			https://spdx.org/licenses/GPL-2.0-or-later.html
##		SPDX-License-Identifier: GPL-2.0-or-later


fMain(){
	set -e

	## Settings
	exePath="../convert-base-v1b"
	baseDefs="base-definitions.sh"
	aliasDefs="alias-definitions.sh"

	## Resolve paths
	fResolvePath  exePath    "${exePath}"
	fResolvePath  baseDefs   "${baseDefs}"
	fResolvePath  aliasDefs  "${aliasDefs}"

	## Load base definitions arrays
	fEcho_Clean
	source "${baseDefs}"
	source "${aliasDefs}"
	fEcho_Clean_Force

	## Variables
	local inputVal=""  expectVal=""  gotVal=""  tmpVal=""
	local -i loopCount=0

	####
	#### Will it even load at all
	####

	fEcho_Clean
	fEcho_Clean "Exe source ...: ${exePath}"
	fEcho_Clean "Version ......: $("${exePath}" --version)"
	fEcho_Clean_Force ; sleep 2
	set +e


	####
	#### Looped quazi-random fuzz-testing
	####

	loopCount=100
	fFuzzTest_BaseToBaseAndBack

:;}


fFuzzTest_BaseToBaseAndBack(){

	## Settings
	local -ri count_OutputBases=28
	local -ri count_MaxInputLen=128
	local -i  random_InputBase=0
	local -i  random_OutputBase=0
	local -i  random_InputLen=0
	local -a  inputBaseArr=()
	local     inputBase=""
	local     inputStr=""
	local     outputBase=""

	for ((i=0; i<loopCount; i++)); do

		## Random input base
		random_InputBase=$((1 + $(od -An -N1 -i /dev/urandom) % count_InputBases))
		case $random_InputBase in
			1) inputBase="2"  ; inputBaseArr=("${base2[@]}")   ;;
			2) inputBase="8"  ; inputBaseArr=("${base8[@]}")   ;;
			3) inputBase="10" ; inputBaseArr=("${base10[@]}")   ;;
			4) inputBase="16" ; inputBaseArr=("${base16[@]}")  ;;
		#	5) inputBase="26" ; inputBaseArr=("${base26[@]}")  ;;  ## Testing revealed that `bc` can't actually do base-26.
			5) inputBase="36" ; inputBaseArr=("${base36[@]}")  ;;
		esac

		## Random input length
		random_InputLen=$((1 + $(od -An -N1 -i /dev/urandom) % count_MaxInputLen))

		## Random input string
		fScrambleString  inputStr  "$(IFS=; echo "${inputBaseArr[*]}")"   $random_InputLen

		## Random output base
	#	random_OutputBase=$((1 + $(od -An -N1 -i /dev/urandom) % count_OutputBases))
		random_OutputBase=$((1 + $(od -An -N1 -i /dev/urandom) % count_InputBases))
		case $random_OutputBase in
			1)    outputBase="2"            ;;
			2)    outputBase="8"            ;;
			3)    outputBase="10"           ;;
			4)    outputBase="16"           ;;
		#	5)    outputBase="26"           ;;  ## Testing revealed that `bc` can't actually do base-26.
			5)    outputBase="36"           ;;
		#	7)    outputBase="32c"          ;;
		#	8)    outputBase="32h"          ;;
		#	9)    outputBase="32r"          ;;
		#	10)   outputBase="32w"          ;;
		#	11)   outputBase="38hostname"   ;;
		#	12)   outputBase="39username"   ;;
		#	13)   outputBase="45email"      ;;
		#	14)   outputBase="48j1w"        ;;
		#	15)   outputBase="48v1compat"   ;;
		#	16)   outputBase="52"           ;;
		#	17)   outputBase="62"           ;;
		#	18)   outputBase="64h"          ;;
		#	19)   outputBase="64j1"         ;;
		#	20)   outputBase="64j1w"        ;;
		#	21)   outputBase="64r"          ;;
		#	22)   outputBase="64u"          ;;
		#	23)   outputBase="64v1compat"   ;;
		#	24)   outputBase="128j1"        ;;
		#	25)   outputBase="128j1w"       ;;
		#	26)   outputBase="128v1compat"  ;;
		#	27)   outputBase="256j1"        ;;
		#	28)   outputBase="288j1"        ;;
		esac

		## To avoid falsely triggering an error:
		## Strip off leading symbols representing '0' from input, which will be gone from the output during conversion.
		shopt -s extglob
		inputStr="${inputStr##+("${inputBaseArr[0]}")}"
		[[ -z "${inputStr}" ]]  &&  continue
		expectVal="${inputStr}"

		## Format and prepare the first command for display, to be shown in output (via variable "hook")
		local exeName=""  exeArgs=""
		fGetIsolatedExeName  exeName  exeArgs  "'${exePath}'  --ibase ${inputBase}  '${inputStr}'  ${outputBase}"
		__fRunTest_EchoHook1="Cmd 1 ..........: '${exeName}'${exeArgs}"

		## Run the first command, to get the intermediate output for the second
		cmd1Output_cmd2Input="$("${exePath}"  --ibase ${inputBase}  "${inputStr}"  ${outputBase})"

		## Run the second command with the previous command's output as this command's input.
		## This command's output should be the same as the previous command's input.
		fRunTest  '=='  "${expectVal}"  "'${exePath}'  --ibase ${outputBase}  ${cmd1Output_cmd2Input}  ${inputBase}"

	done

}


fTestAllAliases(){
	local -r inputBase="${1:-}"  ; shift || true
	local -r inputVal="${1:-}"   ; shift || true
	for nextBase in "${baseAliasesArr[@]}"; do
		fRunTest  'no_error'  ""  "'${exePath}'  --ibase ${inputBase}  ${inputVal}  ${nextBase}"
	done
}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Generic function prototypes for reference and linting correctness. Overridden with real function when generic script is sourced at the bottom of this script.
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fEntryPoint(){
	local -i count_Tests=0
	local -i count_Passed=0
	local -i count_Failed=0
:;}
fRunTest(){
	local -r  testMode="${1:-}"   ; shift || true   ## 'equal', 'notequal', 'error'.
	local -r  expectVal="${1:-}"  ; shift || true   ## Inherit from parent instead.
	local -r  cmdStr="${1:-}"     ; shift || true
:;}
fRunChained_TestLast(){
	local -r  testMode="${1:-}"   ; shift || true   ## 'equal', 'notequal', 'error'.
	local -r  expectVal="${1:-}"  ; shift || true   ## Inherit from parent instead.
	local -r  cmdStrs="${1:-}"    ; shift || true   ## >=1 commands with ';' as delimiter.
:;}
fPipe_LogAndShowPartialOutput_InitLogfile(){
	local filePath_Log="${1:-}" ; shift || true  ## If you want to override the logfile path. Otherwise it's the path of this script+basename, + '.log'.
:;}
fPipe_LogAndShowPartialOutput(){ :; }
fPipe_LogOnly(){ :; }
fGetIsolatedExeName(){
	local -n  retVarName_CmdName_1myq1b5="${1:-}"   ; shift || true   ## The parent variable to populate with the isolated command 'basename' (no path).
	local -n  retVarName_TheRest_1myq1b5="${1:-}"   ; shift || true   ## The parent variable to populate with the rest of the command-line after the executable.
	local -r  commandString="${1:-}"                ; shift || true   ## The full command line
:;}
fScrambleString(){
	local -n  outputVarName_1myn9vt=${1:-}   ; shift || true  ## The parent variable to put the results in. The results should have no spaces, unless a space is one of the inputs as a symbol to randomize.
	local -r  inputSymbolList="${1:-}"       ; shift || true  ## List of symbols to scramble, as a regular UTF-8 bash string. Will have no spaces or delimiters, unless a space is one of the inputs as a symbol to randomize.
	local -ri outputLen=${1:-1}              ; shift || true  ## Output scrambled string length
	local -ri canRepeatChars=${1:-1}         ; shift || true  ## 0: Don't repeat any symbols if possible (i.e. if input len > output len). 1: Try to repeat symbols in the random output.
}
fTallyResult(){
	local -ri errNum=${1:-0}      ; shift || true  ## The integer return value from the command.
	local -r  testMode="${1:-}"   ; shift || true  ## 'equal', 'notequal', 'error'.
	local -r  expectVal="${1:-}"  ; shift || true  ##
	local -r  gotVal="${1:-}"     ; shift || true  ##
:;}
fEcho_ResetBlankCounter()     { :; }
fEcho_WasLastEchoBlank_Set()  { local -i arg1=${1:-0}; }
fEcho_WasLastEchoBlank_Get()  { return 0; }
fEcho_IsInRawInlineMode_Set() { local -i arg1=${1:-0}; }
fEcho_IsInRawInlineMode_Get() { return 0; }
fEcho_Clean()             { local -i arg1="${1:-0}"; }
fEcho()                   { local -i arg1="${1:-0}"; }
fEcho_Force()             { local -i arg1="${1:-0}"; }
fEcho_Clean_Force()       { local -i arg1="${1:-0}"; }


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
## Generic function(s) that can't be 'sourced'.
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fResolvePath(){
	## First looks at specified raw path. Next, same path but relative to this script. Next, in $PATH for an executable. Next, in this script's path, + /lib, /include, then /includes.
	local -n parentVarName_ResolvedPath_t4rej=${1:-}  ; shift || true  ## Parent variable to store fully resolved path in.
	local    nameOrPath="${1:-}"                      ; shift || true  ## File or folder path (relative or absolute). If an executable file, can be just a name to search in $PATH, to fully resolve.
	local -i mustExist=${1:-1}                        ; shift || true  ## 1 [default]: path must exist or error occurs. 0: Just rationalize paths.
	[[   -z "${nameOrPath}" ]]  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): No path specified to resolve.\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	local -r mePath_t4rmy="$(dirname "${BASH_SOURCE[0]}")"
	local -i isNopathObject=0 ; [[ "${nameOrPath}" == "$(basename "${nameOrPath}")" ]] && isNopathObject=1 ; readonly isNopathObject
	local    testPath="${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]]                          ; }  &&  testPath="${mePath_t4rmy}/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject))    ; }  &&  testPath="$(which "${nameOrPath}" 2>/dev/null || true)"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject))    ; }  &&  testPath="${mePath_t4rmy}/lib/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject))    ; }  &&  testPath="${mePath_t4rmy}/include/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isNopathObject))    ; }  &&  testPath="${mePath_t4rmy}/includes/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((mustExist))         ; }  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔc].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	{ [[ ! -e "${testPath}"   ]] || [[ -z "${testPath}" ]]; }  &&  testPath="${nameOrPath}"  ## Revert to original definition
	if ((mustExist)); then testPath="$(realpath -e "${testPath}" 2>/dev/null || true)"
	else                   testPath="$(realpath -m "${testPath}" 2>/dev/null || true)"; fi
	## Last check to fail on
	{ [[ -z "${testPath}" ]] || { [[ ! -e "${testPath}" ]] && ((mustExist)); }; }  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔs].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	## Success
	parentVarName_ResolvedPath_t4rej="${testPath}"
}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
# Entry point
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••

if [[ -z "${meName_t4rgd+x}" ]]; then
	declare -r mePath_t4rgd="${BASH_SOURCE[0]}"
	declare -r meName_t4rgd="$(basename "${mePath_t4rgd}")"
	declare -r meDir_t4rgd="$(dirname "${mePath_t4rgd}")"
	declare -r serialDT_t4rgd="$(date "+%Y%m%d-%H%M%S")"
fi


## Source the generic script 'utility/n8test'. It will call fMain() above.
declare n8test_resolved="../utility/n8test"
fResolvePath  n8test_resolved  "${n8test_resolved}" ; readonly n8test_resolved
[[ -z "${n8test_resolved}" ]] || source "${n8test_resolved}"

## Initialize logging (fPipe_LogAndShowPartialOutput_InitLogfile() is defined in 'n8test')
declare logFile="${mePath_t4rgd%.*}.log"
fResolvePath  logFile    "${logFile}"  0
fPipe_LogAndShowPartialOutput_InitLogfile "${logFile}"

## Kick off testing (functions are defined in 'n8test')
fEntryPoint | fPipe_LogAndShowPartialOutput



#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
##	Script history:
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
##		- 20260420 JC: Copied test.sh to test_against_v2.sh.
