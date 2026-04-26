#!/bin/bash
# shellcheck disable=SC2034  ## Don't complain about unused variables.
# shellcheck disable=SC2207  ## 'Prefer mapfile or read -a to split command output (or quote to avoid splitting).' (Applies to most or all of the base definitions below.)
# shellcheck disable=SC2178  ## False warning about array references.
# shellcheck disable=SC2317  ## Unreachble code. Makes debugging visually harder.
# shellcheck disable=SC2329  ## The function is never invoked.

LANG="C.UTF-8"

## Only allow running 'sourced'.
declare -i isSourced_t4rfy; { (return 0 2>/dev/null) && isSourced_t4rfy=1; } || isSourced_t4rfy=0
((! isSourced_t4rfy)) && { echo -e "\nThis script is meant to be 'sourced' from within another script.\n"; exit 1; }

####
#### Base definitions copied directly from convert-base-v1b (which we'll then need to package better for testing purposes):

## Bases
declare -ra base2=($(echo {0..1}))
declare -ra base8=($(echo {0..7}))
declare -ra base10=($(echo {0..9}))
declare -ra base16=($(echo {0..9} {A..F}))
declare -ra base32h=($(echo {0..9} {A..V})) #.............................................. RFC 4648 hex
declare -ra base32r=($(echo {A..Z} {2..9})) #.............................................. RFC 4648
declare -ra base32w=(2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x) #.... Wordsafe
declare -ra base64r=($(echo {A..Z} {a..z} {0..9} "+ /")) #................................. RFC 4648
declare -ra base64u=($(echo {A..Z} {a..z} {0..9} "- _")) #................................. RFC 4648 url-safe variant

## De-facto standards
declare -ra base26=($(echo {A..Z}))
declare -ra base32c=(0 1 2 3 4 5 6 7 8 9 A B C D E F G H J K M N P Q R S T V W X Y Z) #.... Crockford; no I, L, O, U; one famous programmer's proposal that has become a more-or-less de-facto accepted standard variant.
declare -ra base36=($(echo {0..9} {A..Z})) #............................................... Base36
declare -ra base52=($(echo {A..Z} {a..z}))
declare -ra base62=($(echo {0..9} {A..Z} {a..z})) #........................................ Base62

## Very slight custom modifications
declare -ra base64h=($(echo {0..9} {A..Z} {a..z} "- _")) #................................. Hex-style base 64
declare -ra base64jc1=($(echo {0..9} {A..Z} {a..z} "ʞ λ")) #................................ Like 64h but more programmer (and visually) friendly +2 chars at the end. 1% more bytes that 64r|u on average for UTF-8 encoding, if evenly-distributed.

## Custom 'word-safe', URL-safe, filesystem-safe, and programmer-friendly variants that strive to be CLI-width-friendly (but may not always render properly in every terminal or program with every font).
## Note: Redefining these constitutes a breaking change with v1. But backward-compatible aliases are included below.
declare -ra base48jc1ws=(2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥)
declare -ra base64jc1ws=(2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ)
declare -ra base128jc1ws=(2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ Ξ ψ Ϡ δ ϟ Ћ Ж Я Ѣ ф ¢ £ ¥ § ¿ ɤ ʬ ⍤ ⍩ ⌲ ⍋ ⍒ ⍢ Â Ĉ Ê Ĝ Ĥ Î Ĵ Ô Ŝ Û Ŵ Ŷ Ẑ â ĉ ê ĝ ĥ î ĵ ô ŝ û ŵ ŷ ẑ Ã Ẽ Ĩ Ñ Õ Ũ Ỹ ã ẽ ĩ ñ õ ũ ỹ Ä)

## "Incorrect" backwards-compatiable with v1: Custom 'word-safe', URL-safe, filesystem-safe, and programmer-friendly variants that strive to be CLI-width-friendly (but may not always render properly in every terminal or program with every font).
declare -ra base48v1compat=(0 1 2 3 4 5 6 7 8 9 c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑)
declare -ra base64v1compat=(0 1 2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠)
declare -ra base128v1compat=(0 1 2 3 4 5 6 7 8 9 C F G H J M P Q R V W X c f g h j m p q r v w x ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ Ξ ψ Ϡ δ ϟ Ћ Ж Я Ѣ ф ¢ £ ¥ § ¿ ɤ ʬ ⍤ ⍩ ⌲ ⍋ ⍒ ⍢ Â Ĉ Ê Ĝ Ĥ Ĵ Ŝ Ŵ Ŷ â ĉ ê ĝ ĥ ĵ ŝ ŵ ŷ Ã Ẽ Ñ Ỹ ã ẽ ñ ỹ Ä Ë Ẅ Ẍ Ÿ ä ë ẅ ẍ ÿ Á Ć É)

## Custom (not 'word-safe'), URL-safe, filesystem-safe, and programmer-friendly variants that strive to be CLI-width-friendly (but may not always render properly in every terminal or program with every font).
declare -ra base128jc1=(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ Ξ ψ Ϡ δ ϟ Ћ Ж Я Ѣ ф ¢ £ ¥ § ¿ ɤ ʬ ⍤ ⍩ ⌲ ⍋ ⍒ ⍢ Â Ĉ Ê Ĝ Ĥ Î Ĵ Ô Ŝ Û Ŵ)
declare -ra base256jc1=(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ Ξ ψ Ϡ δ ϟ Ћ Ж Я Ѣ ф ¢ £ ¥ § ¿ ɤ ʬ ⍤ ⍩ ⌲ ⍋ ⍒ ⍢ Â Ĉ Ê Ĝ Ĥ Î Ĵ Ô Ŝ Û Ŵ Ŷ Ẑ â ĉ ê ĝ ĥ î ĵ ô ŝ û ŵ ŷ ẑ Ã Ẽ Ĩ Ñ Õ Ũ Ỹ ã ẽ ĩ ñ õ ũ ỹ Ä Ë Ï Ö Ü Ẅ Ẍ Ÿ ä ë ï ö ü ẅ ẍ ÿ Á Ć É Ǵ Í Ń Ó Ŕ Ś Ú Ẃ Ý Ź á ć é ǵ í ń ó ŕ ś ú ẃ ý ź Ā Ē Ī Ō Ū Ȳ ā ē ī ō ū ȳ Ǎ Č Ď Ě Ǧ Ȟ Ǩ Ň Ǒ Ř Š Ǔ ǎ č ď ě ǧ ȟ ǩ ň ǒ ř š ǔ ǝ ɹ ʇ ʌ ₸ ᛬ 웃 유 ㅈ ㅊ ㅍ ㅎ ㅱ ㅸ ㅠ ソ ッ ゞ ぅ ぇ ォ)
declare -ra base288jc1=(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ʞ λ μ ᛎ ᛏ ᛘ ᛯ ᛝ ᛦ ᛨ ᚠ ᚧ ᚬ ᚼ 🜣 🜥 🜿 🝅 ▵ ▸ ▿ ◂ ҂ ‡ ± ⁑ ÷ ∞ ≈ ≠ Ω Ʊ Ξ ψ Ϡ δ ϟ Ћ Ж Я Ѣ ф ¢ £ ¥ § ¿ ɤ ʬ ⍤ ⍩ ⌲ ⍋ ⍒ ⍢ Â Ĉ Ê Ĝ Ĥ Î Ĵ Ô Ŝ Û Ŵ Ŷ Ẑ â ĉ ê ĝ ĥ î ĵ ô ŝ û ŵ ŷ ẑ Ã Ẽ Ĩ Ñ Õ Ũ Ỹ ã ẽ ĩ ñ õ ũ ỹ Ä Ë Ï Ö Ü Ẅ Ẍ Ÿ ä ë ï ö ü ẅ ẍ ÿ Á Ć É Ǵ Í Ń Ó Ŕ Ś Ú Ẃ Ý Ź á ć é ǵ í ń ó ŕ ś ú ẃ ý ź Ā Ē Ī Ō Ū Ȳ ā ē ī ō ū ȳ Ǎ Č Ď Ě Ǧ Ȟ Ǩ Ň Ǒ Ř Š Ǔ ǎ č ď ě ǧ ȟ ǩ ň ǒ ř š ǔ ǝ ɹ ʇ ʌ ₸ ᛬ 웃 유 ㅈ ㅊ ㅍ ㅎ ㅱ ㅸ ㅠ ソ ッ ゞ ぅ ぇ ォ ゲ サ じ す ス せ ち づ で ネ ビ べ ぺ ま モ ゟ ヲ ½ ⅓ ⅔ ¼ ¾ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅛ ⅜ ⅝ ⅞)

## Custom; Special: ^[a-z_]([a-z0-9_-]){0,31}$; linux hostname (including domain - not case-sensitive, usually lower-case, and this is just the legal chars): [0-9a-z\-\.]
declare -ra base38hostname=($(echo {0..9} {a..z} "- ."))
declare -ra base39username=($(echo {0..9} {a..z} "- _ ."))
declare -ra base45email=($(echo {0..9} {a..z} "- _ % + . : @ [ ]"))


####
#### Generic functions

fArrayToStr(){
	## Collapses an array to a string, removing spaces - unless one of the elements IS a space.
	local -n parentVarRef_Result_t4s9y=${1:-}      ; shift || true  ## Parent variable reference to store result in.
	local -n parentVarRef_InputArray_t4s9y=${1:-}  ; shift || true  ## Input array to work on.
	parentVarRef_Result_t4s9y=""
	local outputStr=""
	for nexItem in "${parentVarRef_InputArray_t4s9y[@]}"; do  outputStr="${outputStr}${nexItem}"; done
	parentVarRef_Result_t4s9y="${outputStr}"
}

fKeyVal_Add(){
	## Add a key/value pair to a pair of arrays. The assoc array will store the index# to indexed array, referenceable by key.
	## Args
	local -n parentVarRef_Array_KeyToVal=${1:-}   ; shift || true  ## Parent assoc key/val array variable to add to.
	local -n parentVarRef_Array_KeyToIdx=${1:-}   ; shift || true  ## Parent assoc key/idx array variable to add to.
	local -n parentVarRef_Array_IdxToKey=${1:-}   ; shift || true  ## Parent index idx/key array variable to add to.
	local -r keyStr="${1:-}"                      ; shift || true  ## The key to associate with the next value.
	local -r valStr="${1:-}"                      ; shift || true  ## The value to associate with the key.
	## Validate
	[[ -z "${keyStr}"                                     ]]  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The fourth argument - array 'key' - must be specified.\n" 1>&2; return 1; }
	[[ -n "${parentVarRef_Array_KeyToVal["${keyStr}"]:-}" ]]  &&  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The specified key already exists in the associative array: '${keyStr}', with value '${parentVarRef_Array_KeyToVal["${keyStr}"]:-}'.\n" 1>&2; return 1; }
	## Variables
	local -i nextIndex=-1
	## Populate the arrays
	parentVarRef_Array_KeyToVal["${keyStr}"]="${valStr}"
	nextIndex=$((${#parentVarRef_Array_KeyToVal[@]} - 1))
	parentVarRef_Array_KeyToIdx["${keyStr}"]=${nextIndex}
	parentVarRef_Array_IdxToKey[nextIndex]="${keyStr}"
}

fKeyVal_Get_ByKey(){
	## Get a value from the arrays by its key.
	## Args
	local -n parentVarRef_Result_t4sdb=${1:-}     ; shift || true  ## Parent string variable to put return (value) in.
	local -n parentVarRef_Array_KeyToVal=${1:-}   ; shift || true  ## Parent asoc key/val array variable.
	local -r keyStr="${1:-}"                      ; shift || true  ## The key to look up.
	## Validate
	[[ -v parentVarRef_Result_t4sdb                ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The first argument - Parent string return variable - appears to be undefined.\n" 1>&2; return 1; }
	parentVarRef_Result_t4sdb=""
	[[ -n "${keyStr}"                              ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The third argument - array 'key' - can't be empty.\n" 1>&2; return 1; }
	[[ -v parentVarRef_Array_KeyToVal["${keyStr}"]      ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): Key '${keyStr}' not found in array.\n" 1>&2; return 1; }
	## Get the value
	parentVarRef_Result_t4sdb="${parentVarRef_Array_KeyToVal["${keyStr}"]}"
:;}

fKeyVal_Get_ByIdx(){
	## Get a value from the indexed array by its numeric index.
	## Args
	local -n  parentVarRef_Result_t4sdf=${1:-}     ; shift || true  ## Parent string variable to put return value value in.
	local -n  parentVarRef_Array_IdxToKey=${1:-}   ; shift || true  ## Parent index idx/key array variable.
	local -n  parentVarRef_Array_KeyToVal=${1:-}   ; shift || true  ## Parent assoc key/val array variable.
	local -ri idxNum="${1:--1}"                    ; shift || true  ## The 0-based index to look up.
	## Validate
	[[ -v parentVarRef_Result_t4sdf              ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The first argument - Parent string return variable - appears to be undefined.\n" 1>&2; return 1; }
	parentVarRef_Result_t4sdf=""
	[[ "${idxNum}" =~ ^[1-9][0-9]*$              ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): The third argument - 'index' - must be an integer >= 0.\n" 1>&2; return 1; }
	[[ -v parentVarRef_Array_KeyToVal[${idxNum}] ]]  ||  { echo -e "\nError in $(basename "${BASH_SOURCE[0]}").${FUNCNAME[0]}(): Index '${idxNum}' not present in indexed array.\n" 1>&2; return 1; }
	## Get the value
	local tmpKey=""
	tmpKey="${parentVarRef_Array_IdxToKey[idxNum]}"
	parentVarRef_Result_t4sdf="${parentVarRef_Array_KeyToVal["${tmpKey}"]}"
:;}


####
#### Custom functions
#### Pack bases _from_ their own arrays each, _to_ strings in a named and indexed array pair. Idx array needs to use 1 as starting index, therefor index=0 will ignored.

fAddBase_To_Arrs(){
	## Args
	local -ri alsoAddToInputBaseArrs=${1:-0}   ; shift || true  ## 0 [default]: Add only to output arrays. 1: Add to input arrays to.
	local -r  baseName=${1:-0}                 ; shift || true  ## Name of the base to use as a key.
	local -n  parentVarRef_baseArray=${1:-0}   ; shift || true  ## The array to collapse into a value and store as key/value.
	## Get string from base array
	local tmpStr=""
	fArrayToStr  tmpStr  parentVarRef_baseArray
	## Add to output base arrays
	fKeyVal_Add  bases_Output_KeyToVal  bases_Output_KeyToIdx  bases_Output_IdxToKey  "${baseName}"  "${tmpStr}"
	((alsoAddToInputBaseArrs))  &&  fKeyVal_Add  bases_Input_KeyToVal  bases_Input_KeyToIdx  bases_Input_IdxToKey  "${baseName}"  "${tmpStr}"
:;}

declare -A bases_Output_KeyToVal=() ; declare -A bases_Output_KeyToIdx=()  ; declare -a bases_Output_IdxToKey ;
declare -A bases_Input_KeyToVal=()  ; declare -A bases_Input_KeyToIdx=()   ; declare -a bases_Input_IdxToKey ;

## All bases
fAddBase_To_Arrs  1    "2"            base2
fAddBase_To_Arrs  1    "8"            base8
fAddBase_To_Arrs  1   "10"           base10
fAddBase_To_Arrs  1   "16"           base16
fAddBase_To_Arrs  0   "26"           base26
fAddBase_To_Arrs  0   "32r"          base32r
fAddBase_To_Arrs  0   "32h"          base32h
fAddBase_To_Arrs  0   "32c"          base32c
fAddBase_To_Arrs  0   "32w"          base32w
fAddBase_To_Arrs  1   "36"           base36
fAddBase_To_Arrs  0   "38hostname"   base38hostname
fAddBase_To_Arrs  0   "39username"   base39username
fAddBase_To_Arrs  0   "45email"      base45email
fAddBase_To_Arrs  0   "48jc1ws"      base48jcw
fAddBase_To_Arrs  0   "48v1compat"   base48v1compat
fAddBase_To_Arrs  0   "52"           base52
fAddBase_To_Arrs  0   "62"           base62
fAddBase_To_Arrs  0   "64r"          base64r
fAddBase_To_Arrs  0   "64u"          base64u
fAddBase_To_Arrs  0   "64h"          base64h
fAddBase_To_Arrs  0   "64jc1"        base64jc
fAddBase_To_Arrs  0   "64jc1ws"      base64jcw
fAddBase_To_Arrs  0   "64v1compat"   base64v1compat
fAddBase_To_Arrs  0  "128jc1"       base128jc
fAddBase_To_Arrs  0  "128jc1ws"     base128jcw  ##
fAddBase_To_Arrs  0  "128v1compat"  base128v1compat
fAddBase_To_Arrs  0  "256jc1"       base256jc
fAddBase_To_Arrs  0  "288jc1"       base288jc

##DEBUG; list output arrays
#declare    strVal=""
#declare -i intIdx=0
#declare    allStr=""
#for nextKey in "${!bases_Output_KeyToIdx[@]}"; do
#	intIdx=${bases_Output_KeyToIdx["${nextKey}"]}
#	strVal="${bases_Output_KeyToVal["${nextKey}"]}"
#	allStr="${allStr}${intIdx}\t${nextKey}\t${strVal}\n"
#done
#allStr="$(echo -e "${allStr}" | sort -k 2 -g)"
#allStr="IDX\tKEY\tVAL\n${allStr}"
#echo -e "${allStr}" | column -t -s $'\t'
#exit

echo "[ Base definitions loaded. ]"
