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


##	Purpose: CI/CD-friendly test harness that passes or fails.
##	History: At bottom of this file. (Note: History for this is maintained outside of [or in addition to] git project.)

##	Copyright
##		Copyright © 2026 Jim Collier (ID: 1cv◂‡Vᛦ)
##		Licensed under the GNU General Public License v2.0 or later. Full text at:
##			https://spdx.org/licenses/GPL-2.0-or-later.html
##		SPDX-License-Identifier: GPL-2.0-or-later


## Settings
declare -r exePath="$(realpath -e "$(dirname "${0}")/../convert-base-v1b")"


fUnitTest(){

	## Variables
	local inputVal=""  expectVal=""  gotVal=""  tmpVal=""
	local -i loopCount=0

	## Load base definitions array
	source "$(dirname "${BASH_SOURCE[0]}")/base-definitions.sh"

	## Will it even load at all
	fEcho_Clean; fEcho_Clean "${exePath}"
	"${exePath}" --version ; fEcho_WasLastEchoBlank_Set 1 ; sleep 1

	## Test val to use for next few sections
	inputVal="00012345678999999999999999901234567899999999999999991234567899999999900000000000000000000000000000000000000000000000999999999999999999999999999999999999998765432100"

	####
	#### By-hand one-way tests, expect equal
	####

	## 128v1compat
	#expectVal="$(convert-base-v1  "${inputVal}"  128j1)"  #; echo "${expectVal}"
	expectVal="ẽ🝅q¥fᚧ▵jj⍩Ξ4⍩ŷᚠMϠÿ≈⍤prẌŶãʞ1HÃ⍋ϟ‡mpcδñjĥWHᚼh▿ĉp⍢ỹʬ1QfẅF1VpλμɤЖG2ĵ5Ϡ⍋Éw≠Éẍ🝅ᛘẅμ"
	fRunTest  '=='  "'${exePath}'  ${inputVal}  128v1compat"

	## 128j1
	#expectVal="$(convert-base-v2  "${inputVal}"  128jc)"  # ; echo "${expectVal}" | ct
	expectVal="⍩pT🜿NjqQQ҂ᛏ4҂¥iFᛯÔʞ◂SUĈδ⍤Y1D§±ᛦvRSMᛝ⌲QѢKDlPsЋS÷⍋▿1HNÎB1JSZa▸ᚠC2ф5ᛯ±ŴWλŴĴpdÎa"
	fRunTest  '=='  "'${exePath}'  ${inputVal}  128j1"

	####
	#### By-hand one-way tests, expect NOT equal
	####

	## 128j1 != 128v1compat
	#expectVal="$(convert-base-v1  "${inputVal}"  128j1)"  #; echo "${expectVal}"
	expectVal="ẽ🝅q¥fᚧ▵jj⍩Ξ4⍩ŷᚠMϠÿ≈⍤prẌŶãʞ1HÃ⍋ϟ‡mpcδñjĥWHᚼh▿ĉp⍢ỹʬ1QfẅF1VpλμɤЖG2ĵ5Ϡ⍋Éw≠Éẍ🝅ᛘẅμ"
	fRunTest  '!='  "'${exePath}'  ${inputVal}  128j1"

	####
	#### By-hand round-trips self-tests, expect equal.
	####

	expectVal="12345678999999999999999901234567899999999999999991234567899999999900000000000000000000000000000000000000000000000999999999999999999999999999999999999998765432100"
	fRunChained_TestLast  '=='  "'${exePath}'  --ibase 10  ${inputVal}  base16 ; '${exePath}'  --ibase 16  %CMD1_OUTPUT%  base10"

	####
	#### By-hand one-way tests, expect ERROR
	####

	## Removed base 16 as input, should error.
	expectVal=""
	fRunTest  'error'  "'${exePath}'  --ibase 26  'ABCXYZ'  10"

	####
	#### Looped self-comparing runs with random input base, input length, base-appropriate input symbols, and output base
	####

	loopCount=100
	fFuzzTest_Self


:;}


fFuzzTest_Self(){

	## Settings
	local -ri count_InputBases=5
#	local -ri count_OutputBases=28
	local -ri count_OutputBases=5
	local -ri count_MaxInputLen=64
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
		fRunTest  '=='  "'${exePath}'  --ibase ${outputBase}  ${cmd1Output_cmd2Input}  ${inputBase}"

	done

}


#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
# Generic code
#•••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
fMain(){
	local -i count_Tests=0
	local -i count_Passed=0
	local -i count_Failed=0
	set +e
		fUnitTest
	set -e
	fEcho_Clean; fEcho_Clean "Results:"
	fEcho_Clean "Total tests .........: ${count_Tests}"
	fEcho_Clean "Passed ..............: ${count_Passed}"
	fEcho_Clean "Failed ..............: ${count_Failed}"
	fEcho_Clean "Expected errors .....: ${count_Errors_Expected}"
	fEcho_Clean "Unexpected errors ...: ${count_Errors_Unexpected}"
	fEcho_Clean
	((count_Failed == 0))  ||  exit 1
}

declare -i currentPassStreak=0
declare    __fRunTest_EchoHook1=""
fRunTest(){
	local -r  testMode="${1:-}"   ; shift || true   ## 'equal', 'notequal', 'error'.
#	local -r  expectVal="${1:-}"  ; shift || true   ## Inherit from parent instead.
	local -r  cmdStr="${1:-}"     ; shift || true

	local -i  errNum=0
	local     gotVal=""
	local -ri prevCount_Passed=${count_Passed}
	local -ri prevCount_Failed=${count_Failed}
	local -ri prevCount_Errors_Expected=${count_Errors_Expected}
	local -ri prevCount_Errors_Unexpected=${count_Errors_Unexpected}

	((++count_Tests))

	## Run the test
	if [[ "${testMode}" ==  'err'* ]]; then
		isExpectingError=1
		fEcho; fEcho "Test #${count_Tests} Expecting error, BEGIN ..."
		gotVal="$(eval "${cmdStr}"  2> >(fPipe_LogOnly >&2))" ; errNum=$? ; true  ## Send error messages to both stderr, and log
		fEcho "Test #${count_Tests} Expecting error, END."; fEcho
		isExpectingError=0
	else
		gotVal="$(eval "${cmdStr}"  2> >(fPipe_LogOnly >&2))" ; errNum=$? ; true  ## Send error messages to both stderr, and log
	fi
	fTallyResult  $errNum  "${testMode}"  "${expectVal}"  "${gotVal}"

	if ((count_Errors_Expected > prevCount_Errors_Expected)); then
		## Action if the test errored as expected
		currentPassStreak=0
	fi

	## Show output based on test results

	fEcho_Clean

	if ((count_Passed > prevCount_Passed)); then
		## Action if the test passed; includes "successful" error caught above.
	#	{ ((currentPassStreak <= 0)) && fEcho_Clean; echo -n "Test #s passed: ${count_Tests}, "; } || echo -n "${count_Tests}, "; fEcho_IsInRawInlineMode_Set 1
		currentPassStreak=$count_Passed
		fEcho_Clean "✅ Passed: Test# ${count_Tests} [Test mode: '${testMode}']"
	elif ((count_Failed > prevCount_Failed)); then
		## Action if the test failed
		currentPassStreak=0
		fEcho_Clean "❌ FAILED: Test# ${count_Tests} [Test mode: '${testMode}']"
	elif ((count_Errors_Unexpected > prevCount_Errors_Unexpected)); then
		## Action if the test UN-expectedly errored
		fEcho_Clean "⚠️ Errored unexpectedly: Test# ${count_Tests} [Test mode: '${testMode}']"
	fi

	local exeName=""  exeArgs=""
	fGetIsolatedExeName  exeName  exeArgs  "${cmdStr}"
	[[ -n "${__fRunTest_EchoHook1:-}" ]] && { fEcho_Clean "${__fRunTest_EchoHook1:-}"; __fRunTest_EchoHook1=""; }
	fEcho_Clean "Test command ...: '${exeName}'${exeArgs}"
	fEcho_Clean "Expected value .: '${expectVal}'"
	fEcho_Clean "Actual value ...: '${gotVal}'"
	fEcho_Clean

:;}

fGetIsolatedExeName(){
	## If called like: fGetIsolatedExeName  executableName  theRestOfCommand  "'/my/path/to/MyExecutable' --arg1 'arg2'", this function will:
	##	- Set caller's variable $executableName to "MyExecutable".
	##	- Set caller's variable $theRestOfCommand to " --arg1 'arg2'".
	local -n  retVarName_CmdName_1myq1b5="${1:-}"   ; shift || true   ## The parent variable to populate with the isolated command 'basename' (no path).
	local -n  retVarName_TheRest_1myq1b5="${1:-}"   ; shift || true   ## The parent variable to populate with the rest of the command-line after the executable.
	local -r  commandString="${1:-}"                ; shift || true   ## The full command line
	retVarName_CmdName_1myq1b5=""
	retVarName_TheRest_1myq1b5=""
	local isolatedExeName=""
	local strAfterThat=""
	isolatedExeName="$(echo "${commandString}" | grep -oP "\'[^\']*\'" | head -n 1)"
	strAfterThat=${commandString#*"${isolatedExeName}"}
	isolatedExeName="$(basename "${isolatedExeName}")"
	isolatedExeName="${isolatedExeName#\'}"; isolatedExeName="${isolatedExeName%\'}"
	retVarName_CmdName_1myq1b5="${isolatedExeName}"
	retVarName_TheRest_1myq1b5="${strAfterThat}"
}

fRunChained_TestLast(){
	## Args
	local -r  testMode="${1:-}"   ; shift || true   ## 'equal', 'notequal', 'error'.
	local -r  cmdStrs="${1:-}"    ; shift || true   ## >=1 commands with ';' as delimiter.
	## Variables
	local -a  cmdArr=()
	local -a  cmdOutputs=()
	local     nextCmd=""
	local     namedcmdOutputs=""
	local -i  lastNonEmptyIdx=0
	## Parse commands into array
	IFS=';' read -ra cmdArr <<< "${cmdStrs}"
	## Find highest non-empty value
	for ((i=0; i<${#cmdArr[@]}; i++)); do [[ -n "${cmdArr[i]//[[:space:]]/}" ]]  &&  lastNonEmptyIdx=i; done
	## Loop to highest non-empty
	for ((i = 0; i <= lastNonEmptyIdx; i++)); do
		nextCmd="${cmdArr[i]}"
		nextCmd="${nextCmd#"${nextCmd%%[![:space:]]*}"}"
		nextCmd="${nextCmd%"${nextCmd##*[![:space:]]}"}"
		((i > 0))  &&  nextCmd="${nextCmd//"%CMD${i}_OUTPUT%"/"${cmdOutputs[i-1]:-}"}"  ## '%CMDn_OUTPUT%' is 1-based, array is 0-based.
		if ((i == lastNonEmptyIdx)); then
			## It's the last one so test it
			fRunTest  "${testMode}"  "${nextCmd}"
		else
			## Run normally
			cmdOutputs[i]="$(eval "${nextCmd}")"
		fi
	done
:;}

##
## Shows piped input  terminal but truncated to terminal width. Also logs the whole line to a date/time-stamped file. Handles wide unicode.
##
declare __fPipe_LogAndShowPartialOutput_LogFile=""
fPipe_LogAndShowPartialOutput_InitLogfile(){
	local filePath_Log="${1:-}" ; shift || true  ## If you want to override the logfile path. Otherwise it's the path of this script+basename, + '.log'.
	[[ -n "${filePath_Log}" ]]  ||  filePath_Log="${BASH_SOURCE[0]%.*}.log"
	[[ -d "$(dirname "${filePath_Log}")" ]]  ||  { echo -e "\nError in $(basname "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): Directory for logfile not found: '$(dirname "${filePath_Log}")'.\n" ; return 1; }
	[[ -f "${filePath_Log}.prev" ]] && rm                    "${filePath_Log}.prev"
	[[ -f "${filePath_Log}"      ]] && mv "${filePath_Log}"  "${filePath_Log}.prev"
	__fPipe_LogAndShowPartialOutput_LogFile="${filePath_Log}"
	touch "${__fPipe_LogAndShowPartialOutput_LogFile}"
}
fPipe_LogAndShowPartialOutput() {
	## Coded by Claude Opus 4.7 Adaptive, 20260424-070027.

	local LC_ALL=C.UTF-8
	local line now secs frac ms ts cols max_w w cw i len ch cp trunc_idx
	cols=${COLUMNS:-$(tput cols 2>/dev/null)}; cols=${cols:-80}
	max_w=$((cols - 4))

	## Alternatives to probing column width
#	cols=$(tput cols 2>/dev/tty) || cols=80
#	cols=$(stty size </dev/tty 2>/dev/null | cut -d' ' -f2) || cols=80

	while IFS= read -r line || [[ -n $line ]]; do
		now="$EPOCHREALTIME"
		secs="${now%.*}"; frac="${now#*.}"; ms="${frac:0:4}"
		printf -v ts '[%(%Y%m%d-%H%M%S)T.%s]' "$secs" "$ms"
		printf '%s  %s\n' "$ts" "$line" >> "$__fPipe_LogAndShowPartialOutput_LogFile"

		w=0; trunc_idx=-1; len=${#line}
		for ((i=0; i<len; i++)); do
			ch="${line:i:1}"
			printf -v cp '%d' "'$ch"
			if (( cp >= 0x1100  && cp <= 0x115F  )) || (( cp >= 0x2E80  && cp <= 0x9FFF  )) || (( cp >= 0xA000  && cp <= 0xA4CF  )) || (( cp >= 0xAC00  && cp <= 0xD7A3  )) || (( cp >= 0xF900  && cp <= 0xFAFF  )) || (( cp >= 0xFE30  && cp <= 0xFE4F  )) || (( cp >= 0xFF00  && cp <= 0xFF60  )) || (( cp >= 0xFFE0  && cp <= 0xFFE6  )) || (( cp >= 0x1F300 && cp <= 0x1FAFF )) || (( cp >= 0x20000 && cp <= 0x3FFFD )); then
				cw=2
			else
				cw=1
			fi
			if (( trunc_idx < 0 && w + cw > max_w )); then
				trunc_idx=$i
			fi
			w=$((w + cw))
			if (( w > cols )); then
				printf '%s ...\n' "${line:0:trunc_idx}"
				continue 2
			fi
		done
		printf '%s\n' "$line"
	done
}
fPipe_LogOnly() {
	## Send stderr to this, e.g. somecmd 2> >(fPipe_LogOnly >&2) | fPipe_LogAndShowPartialOutput
	## Coded by Claude Opus 4.7 Adaptive, 20260424.
    local LC_ALL=C.UTF-8
    local line now secs frac ms ts
    while IFS= read -r line || [[ -n $line ]]; do
        now="$EPOCHREALTIME"
        secs="${now%.*}"; frac="${now#*.}"; ms="${frac:0:4}"
        printf -v ts '[%(%Y%m%d-%H%M%S)T.%s]' "$secs" "$ms"
        printf '%s  %s\n' "$ts" "$line" >> "$__fPipe_LogAndShowPartialOutput_LogFile"
        printf '%s\n' "$line"
    done
}

fScrambleString(){
	## Coded by Claude Opus 4.7 Adaptive, 20260423-162519

	## Args
	local -n  outputVarName_1myn9vt=${1:-}   ; shift || true  ## The parent variable to put the results in. The results should have no spaces, unless a space is one of the inputs as a symbol to randomize.
	local -r  inputSymbolList="${1:-}"       ; shift || true  ## List of symbols to scramble, as a regular UTF-8 bash string. Will have no spaces or delimiters, unless a space is one of the inputs as a symbol to randomize.
	local -ri outputLen=${1:-1}              ; shift || true  ## Output scrambled string length
	local -ri canRepeatChars=${1:-1}         ; shift || true  ## 0: Don't repeat any symbols if possible (i.e. if input len > output len). 1: Try to repeat symbols in the random output.

	## Required for splitting
	local LC_ALL=C.UTF-8   ## function-scoped; restored on return

	local -i inputLen=${#inputSymbolList}
	local -i i j take remaining
	local	tmp result=''
	local -a chars=() shuffled=()

	## Split UTF-8 input into individual characters (bash string indexing is char-based in a UTF-8 locale).
	for (( i=0; i<inputLen; i++ )); do
		chars+=( "${inputSymbolList:i:1}" )
	done

	if (( canRepeatChars )); then
		## Pick with replacement.
		for (( i=0; i<outputLen; i++ )); do
			result+="${chars[RANDOM % inputLen]}"
		done
	else
		## Fisher-Yates shuffle; re-shuffle each pass if outputLen > inputLen (forced repeats).
		remaining=outputLen
		while (( remaining > 0 )); do
			shuffled=( "${chars[@]}" )
			for (( i=inputLen-1; i>0; i-- )); do
				j=$(( RANDOM % (i+1) ))
				tmp="${shuffled[i]}"; shuffled[i]="${shuffled[j]}"; shuffled[j]="$tmp"
			done
			take=$(( remaining < inputLen ? remaining : inputLen ))
			for (( i=0; i<take; i++ )); do
				result+="${shuffled[i]}"
			done
			remaining=$(( remaining - take ))
		done
	fi

	outputVarName_1myn9vt="$result"
}

fTallyResult(){
	local -ri errNum=${1:-0}      ; shift || true  ## The integer return value from the command.
	local -r  testMode="${1:-}"   ; shift || true  ## 'equal', 'notequal', 'error'.
	local -r  expectVal="${1:-}"  ; shift || true  ##
	local -r  gotVal="${1:-}"     ; shift || true  ##
	case "${testMode,,}" in
		'eq'*|'pass'|'='|'==')      { [[ "${expectVal}"  ==  "${gotVal}" ]]  &&  ((++count_Passed)); }  ||  ((++count_Failed))   ;;
		'noteq'*|'fail'|'!='|'<>')  { [[ "${expectVal}"  !=  "${gotVal}" ]]  &&  ((++count_Passed)); }  ||  ((++count_Failed))   ;;
		'err'*)                     { ((errNum != 0))                        &&  ((++count_Passed)); }  ||  ((++count_Failed))   ;;
		*)                          fEcho_Clean "$(basename "${0}").${FUNCNAME[0]}() - Error: Unexpected second argument. Should be 'equal', 'notequal', or 'error'."; return 1  ;;
	esac
:;}

## Echo-handling
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

## Error-handling
declare -i isExpectingError=0
declare -i count_Errors_Unexpected=0
declare -i count_Errors_Expected=0
#trap 'printf "(line %s) " "$LINENO" "$?" >&2; echo; { ((isExpectingError))  &&  ((++count_Errors_Expected)); }  ||  ((++count_Errors_Unexpected))' ERR
trap '{ ((isExpectingError))  &&  ((++count_Errors_Expected)); }  ||  ((++count_Errors_Unexpected))' ERR


## Error and exit settings
 set   -u  ## Require variable declaration. Stronger than mere linting. But can struggle if functions are in sourced files.
 set   -e  #...................: Exit on errors. This is inconsistent (made a little better with settings below), so eventually may move to 'set +e' (which is more constant work and mental overhead).
#set   +e  #...................: Do NOT exit on errors.
 set   -E  #...................: Propagate ERR trap settings into functions, command substitutions, and subshells.
 set   -o pipefail  #..........: Make sure all stages of piped commands also fail the same.
 shopt -s inherit_errexit  #...: Propagate 'set -e' ........ into functions, command substitutions, and subshells. Will fail on Bash <4.4.
 shopt -s dotglob  #...........: Include usually-hidden 'dotfiles' in '*' glob operations - usually desired.
 shopt -s globstar  #..........: ** matches more stuff including recursion.


fPipe_LogAndShowPartialOutput_InitLogfile
fMain | fPipe_LogAndShowPartialOutput




##	Script history:
##		- 20260420 JC: Copied for convert-base-v2.
##		- 20260421 JC: Added polish.
##		- 20260423 JC: Added fRunChained_TestLast() to be able to test commands that can't be piped.
