#!/bin/bash

## Active shellchecks
# shellcheck disable=1090
# shellcheck disable=1091
# shellcheck disable=2001   ## Complaining about use of sed istead of bash search & replace.
# shellcheck disable=2002   ## Useless use of cat. This works well though and I don't want to break it for the sake of syntax purity.
# shellcheck disable=2004   ## Inappropriate complaining of "$/${} is unnecessary on arithmetic variables."
# shellcheck disable=2119   ## Disable confusing and inapplicable warning about function's $1 meaning script's $1.
# shellcheck disable=2120   ## OK with declaring variables that accept arguments, without calling with arguments (this is 'overloading').
# shellcheck disable=2143   ## Used grep -q instead of echo | grep
# shellcheck disable=2154
# shellcheck disable=2155   ## Disable check to 'Declare and assign separately to avoid masking return values'.
# shellcheck disable=2162
# shellcheck disable=2181
# shellcheck disable=2207
# shellcheck disable=2317   ## Can't reach

## Inactive shellchecks
# shellcheck disable=2034  ## Unused variables.


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

## Global settings
set -e
declare doLongTest=0 ; [[ "${CICDTEST_DO_LONGTEST}" == "1" ]] && doLongTest=1

fMain(){

	## Settings
	exe1="../convert-base-v1b"
	exe2="convert-base-v2"  ## Optional, doesn't need to exist for tests to run and complete.
	baseDefs="base-definitions.sh"
#	aliasDefs="alias-definitions.sh"

	## Environment overrides
	local LANG="C.UTF-8"  ## Splitting won't work correctly without this

	## Resolve paths
	fResolvePath  exe1       "${exe1}"
	fResolvePath  baseDefs   "${baseDefs}"
#	fResolvePath  aliasDefs  "${aliasDefs}"
	fResolvePath  exe2       "${exe2}"       0  ## Doesn't need to exist

	## Compare to exe2?
	local -i doComareWith_v2=0
	[[ -x "${exe2}" ]]  &&  doComareWith_v2=1

	## Load base definitions arrays
	fEcho_Clean
	source "${baseDefs}"
#	source "${aliasDefs}"
	fEcho_Clean_Force

	## Variables
	local inputVal=""  expectVal=""  gotVal=""  tmpVal=""
	local -i loopCount=0

	####
	#### Will it even load at all

	fEcho_Clean
	fEcho_Clean "Exe source ...: ${exe1}"
	fEcho_Clean "Version ......: $("${exe1}" --version)"
	fEcho_Clean_Force
	sleep 1
	if ((doComareWith_v2)); then
		fEcho_Clean "v2 source ....: ${exe2}"
		fEcho_Clean "Version ......: $("${exe2}" --version)"
		fEcho_Clean_Force
		sleep 1
	fi


	####
	#### Test flags (make sure -e is enabled)
	fEcho; fEcho ">>> TESTSECTION: Flags"; fEcho

	fEcho; fEcho "Test --help"
	"${exe1}" --help

	fEcho "Test --about"
	"${exe1}" --about

	fEcho "Test --version (again)"
	"${exe1}" --version
	fEcho_Clean_Force


	####
	#### Test base name aliases
	fEcho; fEcho ">>> TESTSECTION: Base name aliases"; fEcho

	inputVal="987654321000055555555550000123456789" #...................................: The value is less important than just the aliases. But also, a large value shouldn't fail either.
	fTestAllAliases  "base10"  "${inputVal}" #..........................................: All should pass
	fRunTest  'error'  "${expectVal}"  "'${exe1}'  '${inputVal}'  bogusBaseName" #......: This one should fail


	####
	#### Looped random fuzz-testing

	## Loop counters for next sections
	loopCount=100
	((doLongTest))  &&  loopCount=5000

	## Test **AGAINST SELF** (only bases 2, 8, 10, 16, 36)
	fEcho; fEcho ">>> TESTSECTION: Fuzz-testing against self (with output bases necessarily limited to valid input bases)"; fEcho
	fFuzzTest_LowerBases_RandomInOut_Self

	#### Test **AGAINST v2** (all the bases)
	fEcho; fEcho ">>> TESTSECTION: Fuzz-testing against v2 (all bases)"; fEcho
	((doComareWith_v2))  &&  fFuzzTest_Base10_To_BaseX_AndBack_via_v2


	####
	#### Test val to use for next sections
	inputVal="01234567899999999999999990123456789999999999999999123456789999999990000000000000000000000000000000000000000000000099999999999999999999999999999999999999876543210"


	####
	#### By-hand one-way tests, expect equal
	fEcho; fEcho ">>> TESTSECTION: By-hand one-way tests, expect equal"; fEcho

	## 128v1compat
	#expectVal="$(convert-base-v1  "${inputVal}"  128j1)"  #; echo "${expectVal}"
	expectVal="FrĜЋŝĴR2§⁑⍤🝅⌲μr1ϟỹẼ⌲M§ỹλ🜥ψ🝅ᛘêᚼ75ĜᛝmÑ🜥Ĝλŝ▵ϠĜRλΞãᛎ8hÊᛯĝĵΩJĜ▿ĤxŴĵ£Cᛏẅ8ÂψvÉÉδPĝŷ"
	fRunTest  '=='  "${expectVal}"  "'${exe1}'  ${inputVal}  128v1compat"

	## 128j1
	#expectVal="$(convert-base-v2  "${inputVal}"  128jc1)"  # ; echo "${expectVal}" | ct
	expectVal="BUΩᛨ¢ΞI2🝅x◂p‡aU1ᛦ⍋¿‡F🝅⍋ZnᛘpdЖl75ΩfRɤnΩZ¢qᛯΩIZᛏ⍤b8P≠eЯфμEΩsƱXϠф🜥AcÎ8∞ᛘVŴŴᛝGЯ¥"
	fRunTest  '=='  "${expectVal}"  "'${exe1}'  ${inputVal}  128jc1"


	####
	#### By-hand one-way tests, expect NOT equal
	fEcho; fEcho ">>> TESTSECTION: By-hand one-way tests, expect NOT equal"; fEcho

	## 128j1 != 128v1compat
	#expectVal="$(convert-base-v1  "${inputVal}"  128j1)"  #; echo "${expectVal}"
	expectVal="FrĜЋŝĴR2§⁑⍤🝅⌲μr1ϟỹẼ⌲M§ỹλ🜥ψ🝅ᛘêᚼ75ĜᛝmÑ🜥Ĝλŝ▵ϠĜRλΞãᛎ8hÊᛯĝĵΩJĜ▿ĤxŴĵ£Cᛏẅ8ÂψvÉÉδPĝŷ"
	fRunTest  '!='  "${expectVal}"  "'${exe1}'  ${inputVal}  128jc1"


	####
	#### By-hand one-way tests, expect ERROR
	fEcho; fEcho ">>> TESTSECTION: By-hand one-way tests, expect ERROR"; fEcho

	## Removed base 16 as input, should error.
	expectVal=""
	fRunTest  'error'  "[anything or nothing]"  "'${exe1}'  --ibase 26  'ABCXYZ'  10"


	####
	#### By-hand round-trips self-tests, expect equal.
	fEcho; fEcho ">>> TESTSECTION: By-hand round-trip tests, expect equal"; fEcho

	expectVal="1234567899999999999999990123456789999999999999999123456789999999990000000000000000000000000000000000000000000000099999999999999999999999999999999999999876543210"
	fRunChained_TestLast  '=='  "${expectVal}"  "'${exe1}'  --ibase 10  ${inputVal}  base16 ; '${exe1}'  --ibase 16  %CMD1_OUTPUT%  base10"

:;}


fTestAllAliases(){
	local -r inputBase="${1:-}"  ; shift || true
	local -r inputVal="${1:-}"   ; shift || true
	for nextBase in "${baseAliasesArr[@]}"; do
		fRunTest  'no_error'  "[anything or nothing]"  "'${exe1}'  --ibase ${inputBase}  ${inputVal}  ${nextBase}"
	done; :
}

fFuzzTest_LowerBases_RandomInOut_Self(){

	## Settings
	local -ri testMaxInputChars=1024
	local -ri count_TotalDefinedBases_Input=${#bases_Input_IdxToKey[@]}
#	local -ri count_TotalDefinedBases_Output=$count_TotalDefinedBases_Input  ## Output base will be used as an intermediat input base, so has to be the subset of valid v1b input bases.

	## Loop variables
	local -i  tmpRandomBaseIdx=-1
	local -i  random_InputLen=0
	local     inputStr=""
	local     inputBaseName=""
	local     inputBaseSymbols=""
	local     intermediateBaseName=""
	local     intermediateVal=""
	local     exe1name=""
	local     exe1args=""

	for ((i=1; i<=loopCount; i++)); do

		## Get a random input base and its list of symbols
		tmpRandomBaseIdx=$((0 + $(od -An -N1 -tu2 /dev/urandom) % (count_TotalDefinedBases_Input - 1) ))
		inputBaseName="${bases_Input_IdxToKey[tmpRandomBaseIdx]}"
		inputBaseSymbols="${bases_Input_KeyToVal["${inputBaseName}"]}"

		## Get a random input of random in-base symbols, or random length
		random_InputLen=$((1 + $(od -An -N2 -tu2 /dev/urandom) % testMaxInputChars))
		fScrambleString  inputStr  "${inputBaseSymbols}"   $random_InputLen

		## To avoid falsely triggering an error:
		## Strip off leading symbols representing '0' from input, which will be gone from the output during conversion.
		expectVal="${inputStr}"
		until [[ "${expectVal:0:1}" !=  "${inputBaseSymbols:0:1}" ]]; do expectVal="${expectVal:1}"; done
		[[ -z "${expectVal}" ]]  &&  continue  ## If it's empty now, just skip to next test.

		## Pick a random intermediate output base (but use input base because that's what we're limited to here).
		tmpRandomBaseIdx=$((0 + $(od -An -N1 -tu2 /dev/urandom) % (count_TotalDefinedBases_Input - 1) ))
		intermediateBaseName="${bases_Input_IdxToKey[tmpRandomBaseIdx]}"

		## Format and prepare the first command for display, to be shown in output (via variable "hook"); and run it
		exe1name=""  exe1args=""
		fGetIsolatedExeName  exe1name  exe1args  "'${exe1}'  --ibase '${inputBaseName}'  '${expectVal}'  '${intermediateBaseName}'"
		__fRunTest_EchoHook1="Cmd 1 ..........: '${exe1name}'${exe1args}"
		intermediateVal="$("${exe1}"  --ibase "${inputBaseName}"  "${expectVal}"  "${intermediateBaseName}")"

		##DEBUG
		#sleep 2
		#echo
		#echo "inputBaseName ...............: ${inputBaseName}"
		#echo "random_InputLen .............: ${random_InputLen}"
		#echo "inputStr ....................: ${inputStr}"
		#echo "expectVal ...................: ${expectVal}"
		#echo "intermediateBaseName ........: ${intermediateBaseName}"
		#echo "intermediateVal .............: ${intermediateVal}"
		#echo

		## Run the second command with the previous command's output as this command's input.
		## This command's output should be the same as the previous command's input.
		fRunTest  '=='  "${expectVal}"  "'${exe1}'  --ibase '${intermediateBaseName}'  '${intermediateVal}'  '${inputBaseName}'"

	done; :

}

fFuzzTest_Base10_To_BaseX_AndBack_via_v2(){

	## Settings
	local -ri testMaxInputChars=256
	local -ri count_TotalDefinedBases_Output=${#bases_Output_IdxToKey[@]}

	## Loop variables
	local -i  random_InputLen=0
	local     inputStr=""
	local -i  tmpRandomBaseIdx=-1
	local     intermediateBaseName=""
	local     intermediateVal=""
	local     exe1name=""
	local     exe1args=""

	for ((i=1; i<=loopCount; i++)); do

		## Generate a random base 10 number for first input
		random_InputLen=$((1 + $(od -An -N2 -tu2 /dev/urandom) % testMaxInputChars))
		fScrambleString  inputStr  "0123456789"   $random_InputLen

		## To avoid falsely triggering an error:
		## Strip off leading symbols representing '0' from input, which will be gone from the output during conversion.
		shopt -s extglob
		expectVal="${inputStr#"${inputStr%%[!0]*}"}"
		[[ -z "${expectVal}" ]]  &&  continue

		## Pick a random intermediate v1b output -> v2 input base
		tmpRandomBaseIdx=$((0 + $(od -An -N1 -tu2 /dev/urandom) % (count_TotalDefinedBases_Output - 1) ))
		intermediateBaseName="${bases_Output_IdxToKey[tmpRandomBaseIdx]:-}"

		## Format and prepare the first command for display, to be shown in output (via variable "hook"); and run it
		exe1name=""  exe1args=""
		fGetIsolatedExeName  exe1name  exe1args  "'${exe1}'  --ibase 10  '${expectVal}'  '${intermediateBaseName}'"
		__fRunTest_EchoHook1="Cmd 1 ..........: '${exe1name}'${exe1args}"
		intermediateVal="$("${exe1}"  --ibase 10  "${expectVal}"  "${intermediateBaseName}")"

		##DEBUG
		#echo
		#echo "random_InputLen .............: ${random_InputLen}"
		#echo "inputStr ....................: ${inputStr}"
		#echo "expectVal ...................: ${expectVal}"
		#echo "tmpRandomBaseIdx ...: ${tmpRandomBaseIdx}"
		#echo "intermediateBaseName ........: ${intermediateBaseName}"
		#echo "intermediateVal .............: ${intermediateVal}"
		#sleep 5

		## Run the second command with the previous command's output as this command's input.
		## This command's output should be the same as the previous command's input.
		fRunTest  '=='  "${expectVal}"  "'${exe2}'  --from '${intermediateBaseName}'  --to 10  --  '${intermediateVal}'"

	done; :

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
	local -n  outputVarName_1myn9vt=${1:-}   ; shift || true  ## The parent variable to put the results in. The results should have no spaces, unless a space is one of the inputs as a symbol to randomize. But will still work with spaces.
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
	##	Purpose:
	##		- Resolves an argument to a canonical full path, while being careful to not be too broad as to resolve to something else with the same name.
	##		- Resolution priority:
	##			- Exactly as specified.
	##			- "[this script's path]/lib/[specified name if given without a path]"
	##			- "[this script's path]/include/[specified name if given without a path]"
	##			- "[this script's path]/includes/[specified name if given without a path]"
	##			- If specified a name without a path: Find in $PATH
	##			- If doesn't have to exist, and still haven't found it, then just canonicalize original argument
	local -n parentVarName_ResolvedPath_t4rej=${1:-}  ; shift || true  ## Parent variable to store fully resolved path in.
	local    nameOrPath="${1:-}"                      ; shift || true  ## File or folder path (relative or absolute). If an executable file, can be just a name to search in $PATH, to fully resolve.
	local -i mustExist=${1:-0}                        ; shift || true  ## 1 [default]: path must exist or error occurs. 0: Just rationalize paths, doesn't have to exist.
	[[   -z "${nameOrPath}" ]]  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): No file or directory specified to resolve.\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	local -r mePath_t4rmy="$(dirname "${BASH_SOURCE[0]}")"
	local -i isExeWithNoPath=0 ; [[ "${nameOrPath}" == "$(basename "${nameOrPath}")" ]] && isExeWithNoPath=1 ; readonly isExeWithNoPath
	local    testPath="${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]]                          ; }  &&  testPath="${mePath_t4rmy}/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isExeWithNoPath))   ; }  &&  testPath="${mePath_t4rmy}/lib/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isExeWithNoPath))   ; }  &&  testPath="${mePath_t4rmy}/include/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isExeWithNoPath))   ; }  &&  testPath="${mePath_t4rmy}/includes/${nameOrPath}"
	{ [[ ! -e "${testPath}"   ]] && ((isExeWithNoPath))   ; }  &&  testPath="$(which "${nameOrPath}" 2>/dev/null || true)"
	{ [[ ! -e "${testPath}"   ]] && ((mustExist))         ; }  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔc].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	{ [[ ! -e "${testPath}"   ]] || [[ -z "${testPath}" ]]; }  &&  testPath="${nameOrPath}"  ## Revert to original definition
	if ((mustExist)); then testPath="$(realpath -e "${testPath}" 2>/dev/null || true)"
	else                   testPath="$(realpath -m "${testPath}" 2>/dev/null || true)"; fi
	## Last check to fail on
	{ [[ -z "${testPath}" ]] || { [[ ! -e "${testPath}" ]] && ((mustExist)); }; }  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}")·${FUNCNAME[0]}(): Could not resolve path '${nameOrPath}' [£ǝŔs].\n"; fEcho_WasLastEchoBlank_Set 1; return 1; }
	## Success
	#echo "testPath: '${testPath}'"
	#fPressAnyKeyToContinue
	parentVarName_ResolvedPath_t4rej="${testPath}"
}


#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
# Entry point
#••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••

if [[ -z "${meName_t4rgd+x}" ]]; then
	declare -r mePath_t4rgd="$(realpath -e "${BASH_SOURCE[0]}")"
	declare -r meName_t4rgd="$(basename "${mePath_t4rgd}")"
	declare -r meDir_t4rgd="$(dirname "${mePath_t4rgd}")"
	declare -r serialDT_t4rgd="$(date "+%Y%m%d-%H%M%S")"
fi

## Make sure relative paths work
cd "${meDir_t4rgd}"

## Source the generic script 'utility/n8test'. It will call fMain() above.
declare n8test_resolved="../utility/include/n8lib_test"
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
##		- 20260425 JC: Finished.
##		- 20260426 JC: Fixed a bug where base array for testing started at 1 instead of 0, as an artifact a bad earlier design decision.
##		- 20260427 JC:
##			- Updated fResolvePath().
##			- Fixed bugs in loops natural end, caused by not setting `set +e`.
##		- 20260428 JC: Removed now-unnecessary reference to alias-definitions.sh.
