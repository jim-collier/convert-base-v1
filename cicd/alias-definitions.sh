#!/bin/bash
# shellcheck disable=2034  ## Unused variables.
# shellcheck disable=2207

## Only allow running 'sourced'.
declare -i isSourced_t4rhz; { (return 0 2>/dev/null) && isSourced_t4rhz=1; } || isSourced_t4rhz=0
((! isSourced_t4rhz)) && { echo -e "\nThis script is meant to be 'sourced' from within another script.\n"; exit 1; }

declare -a baseAliasesArr=()
declare -a baseAliasesArr_commonBaseNames_v1b_v2=()

__fAddPermutations(){
	baseNumname=${1:-0}
	[[ ${baseNumname} =~ ^[0-9].* ]]  ||  return 1
	baseAliasesArr+=("${baseNumname}")
	baseAliasesArr+=("b${baseNumname}")
	baseAliasesArr+=("base${baseNumname}")
}

fPopulateArray(){

	_commonBaseNames_v1b_v2+=("2")           ; __fAddPermutations    2 ; baseAliasesArr+=("bin") ; baseAliasesArr+=("binary")                                                                                                   #
	_commonBaseNames_v1b_v2+=("8")           ; __fAddPermutations    8 ; baseAliasesArr+=("oct") ; baseAliasesArr+=("octal")                                                                                                    #
	_commonBaseNames_v1b_v2+=("10")          ; __fAddPermutations   10 ; baseAliasesArr+=("dec") ; baseAliasesArr+=("decimal")                                                                                                  #
	_commonBaseNames_v1b_v2+=("16")          ; __fAddPermutations   16 ; baseAliasesArr+=("hex") ; baseAliasesArr+=("hexadecimal")                                                                                              #
	_commonBaseNames_v1b_v2+=("26")          ; __fAddPermutations   26                                                                                                                                                          #
	_commonBaseNames_v1b_v2+=("32r")         ; __fAddPermutations   32 ; __fAddPermutations  "32r"           ; __fAddPermutations  "32rfc"    ; __fAddPermutations  "32rfc4648§6"                                                       #
	_commonBaseNames_v1b_v2+=("32h")         ; __fAddPermutations                            "32h"           ; __fAddPermutations  "32hex"    ; __fAddPermutations  "32rfc4648§7"                                                       #
	_commonBaseNames_v1b_v2+=("32c")         ; __fAddPermutations                            "32c"           ; __fAddPermutations  "32crock"  ; __fAddPermutations  "32crockford"                                                       #
	_commonBaseNames_v1b_v2+=("36")          ; __fAddPermutations   36                                                                                                                                                          #
	_commonBaseNames_v1b_v2+=("52")          ; __fAddPermutations   52                                                                                                                                                          #
	_commonBaseNames_v1b_v2+=("62")          ; __fAddPermutations   62                                                                                                                                                          #
	_commonBaseNames_v1b_v2+=("64r")         ; __fAddPermutations   64 ; __fAddPermutations  "64r"           ; __fAddPermutations  "64rfc"    ; __fAddPermutations  "64rfc4648§4"                                                       #
	_commonBaseNames_v1b_v2+=("64u")         ; __fAddPermutations                            "64u"           ; __fAddPermutations  "64url"    ; __fAddPermutations  "64urlsafe"    ; __fAddPermutations  "64rfc4648§5"                    #
	#                                                                                                                                                                              #
	## JC                                                                                                                                                                          #
	_commonBaseNames_v1b_v2+=("38hostname")  ; __fAddPermutations                            "38hostname"                                                                                                                         #
	_commonBaseNames_v1b_v2+=("39username")  ; __fAddPermutations                            "39username"                                                                                                                         #
	_commonBaseNames_v1b_v2+=("45email")     ; __fAddPermutations                            "45email"                                                                                                                            #
	_commonBaseNames_v1b_v2+=("64jc")        ; __fAddPermutations                            "64j1"          ; __fAddPermutations  "64jc"                                                                                             #
	_commonBaseNames_v1b_v2+=("128jc")       ; __fAddPermutations                           "128j1"          ; __fAddPermutations "128jc"                                                                                             #
	_commonBaseNames_v1b_v2+=("256jc")       ; __fAddPermutations                           "256j1"          ; __fAddPermutations "256jc"                                                                                             #
	_commonBaseNames_v1b_v2+=("288jc")       ; __fAddPermutations                           "288j1"          ; __fAddPermutations "288jc"                                                                                             #
	#                                                                                                                                                                              #
	## Word-safe                                                                                                                                                                   #
	_commonBaseNames_v1b_v2+=("32w")         ; __fAddPermutations                            "32w"                                            ; __fAddPermutations  "32ws"         ; __fAddPermutations  "32wordsafe"                     #
	_commonBaseNames_v1b_v2+=("48jcw")       ; __fAddPermutations                            "48j1w"         ; __fAddPermutations  "48jcw"    ; __fAddPermutations  "48jcws"       ; __fAddPermutations  "48jcwordsafe"                   #
	_commonBaseNames_v1b_v2+=("64jcw")       ; __fAddPermutations                            "64j1w"         ; __fAddPermutations  "64jcw"    ; __fAddPermutations  "64jcws"       ; __fAddPermutations  "64jcwordsafe"                   #
	_commonBaseNames_v1b_v2+=("128jcw")      ; __fAddPermutations                           "128j1w"         ; __fAddPermutations "128jcw"    ; __fAddPermutations "128jcws"       ; __fAddPermutations "128jcwordsafe"                   #
	#                                                                                                                                                                                #
	## Compat                                                                                                                                                                        #
	_commonBaseNames_v1b_v2+=("48v1compat")  ; __fAddPermutations                            "48v1compat"                                                                                                                         #
	_commonBaseNames_v1b_v2+=("64v1compat")  ; __fAddPermutations                            "64v1compat"                                                                                                                         #
	_commonBaseNames_v1b_v2+=("128v1compat") ; __fAddPermutations                           "128v1compat"                                                                                                                         #

	echo "[ Base aliases loaded. ]"

}

fPopulateArray
