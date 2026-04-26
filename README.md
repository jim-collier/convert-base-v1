<!-- markdownlint-disable MD007 -- Unordered list indentation -->
<!-- markdownlint-disable MD010 -- No hard tabs -->
<!-- markdownlint-disable MD033 -- No inline html -->
<!-- markdownlint-disable MD055 -- Table pipe style [Expected: leading_and_trailing; Actual: leading_only; Missing trailing pipe] -->
<!-- markdownlint-disable MD041 -- First line in a file should be a top-level heading -->
<div align="center">

[![!#/bin/bash](https://img.shields.io/badge/-%23!%2Fbin%2Fbash-1f425f.svg?logo=gnu-bash)](https://www.gnu.org/software/bash/)
![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)
![Lifecycle: Stable](https://img.shields.io/badge/Lifecycle-Stable-brightgreen)
![Support](https://img.shields.io/badge/Support-Maintained-brightgreen)
![Status: Passing](https://img.shields.io/badge/Status-Passing-brightgreen)

</div>
<!--
![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Lifecycle: Alpha](https://img.shields.io/badge/Lifecycle-Alpha-orange)
![Lifecycle: Beta](https://img.shields.io/badge/Lifecycle-Beta-yellow)
![Lifecycle: RC](https://img.shields.io/badge/Lifecycle-RC-blue)
![Lifecycle: Stable](https://img.shields.io/badge/Lifecycle-Stable-brightgreen)
![Lifecycle: Deprecated](https://img.shields.io/badge/Lifecycle-Deprecated-red)
![Status: Deprecated](https://img.shields.io/badge/Status-Deprecated-orange)
![Status: Archived](https://img.shields.io/badge/Status-Archived-lightgrey)
![Lifecycle: EOL](https://img.shields.io/badge/Lifecycle-EOL-lightgrey)
![Coverage](https://img.shields.io/badge/Coverage-25%25-red)
![Coverage](https://img.shields.io/badge/Coverage-50%25-orange)
![Coverage](https://img.shields.io/badge/Coverage-75%25-yellow)
![Coverage](https://img.shields.io/badge/Coverage-90%25-brightgreen)
![Status: Passing](https://img.shields.io/badge/Status-Passing-brightgreen)
![Status: Failing](https://img.shields.io/badge/Status-Failing-red)
-->

<!-- TOC ignore:true -->
# convert-base-v1b

<!-- TOC ignore:true -->
## Table of contents

<!-- TOC -->

- [Introduction](#introduction)
- [Limitations](#limitations)
- [Input bases](#input-bases)
- [Output bases](#output-bases)
- [Example output](#example-output)
- [Why is the version in the command name](#why-is-the-version-in-the-command-name)
- [Document history](#document-history)
- [Copyright and license](#copyright-and-license)

<!-- /TOC -->

## Introduction

Converts arbitrarily large integers between many common predefined standard bases, as well as some large custom bases up to base-288.

It converts _from_ base-2 up to base-36, and _to_ base-2 up to base-288.

This is a __positional notation base converter__. _Not_ a streaming binary-to-text encoder/decoder. (Therefore, there's no concept of "padding", as there is with binary-to-text encoding/decoding tools.)

It can and does still work with common binary-to-text encoding/decoding bases, like base-32 and base-64. (Just not in the way that tools like `basenc` do.)

There are myriad and unpredictable reasons why one might wish to use a CLI tool to convert between numeric bases.

One handy (but trivial) example: Convert a large integer from base-10 to base-128, to represent it in about half the number of symbols. For example, POSIX time (the number of seconds since 1970) can be used as a "unique" serial value, in a shorter form. Specifically, "2026-01-01 @ 12:15 PM" could be represented as "1fLcL4" in standard base-64url, or "£±Яᛯ" in base-256.

At larger non-standard custom bases, careful effort was made to:

- Avoid ambiguous characters that look like existing 0-9 A-Z ASCII characters and symbols.

- Avoid characters that are too tall or wide and render poorly on fixed-width terminals.

- Avoid reserved characters across multiple operating systems and web standards, so that output can be used in those contexts. (Except for predefined standard base definitions that specify such characters, e.g. regular base-64.)

- Preserve code point sorting where possible, but favor reordering for incremental visual consistency where appropriate. (For example rather than cycling through all "left arrows" in code point order, it might make more sense for an incrementing number to cycle through rotating directions of a given arrow style.)

- Keep the character selection consistent across bases.

## Limitations

- Currently, two-way conversion is only possible with a subset of _input_ bases from base-2, up to base-36.

	But beyond base-36 (e.g. base-64, base-256, etc.), it's a one-way function - you can only get bases larger than 36, as output. Which sort of acts like a one-way hash function - which can be very useful, but is something you need to be aware of it.

	While this script will be supported indefinitely into the future (as it's used in production environments), it's unlikely to ever be a universal "any base in, any base out" utility. That is specifically planned for a `v2` binary executable. (But that doesn't mean it's not highly useful as-is.)

- There's no binary-to-text encoding/decoding. That's an entirely different problem domain. (Which `v2` might attempt to tackle as an alternate code path.)

- No support for `stdin` (e.g. pipes). Another feature for `v2`.

## Input bases

You can convert a value in one of these input numeric bases, to any other base in "Output bases", larger or smaller.

| Base        | Description                                                 | Characters
| :--         | :--                                                         | :--
| 2           | Binary                                                      | 0,1
| 8           | Octal                                                       | 0-7
| 10          | Decimal [default]                                           | 0-9
| 16          | Hexadecimal                                                 | 0-9, A-F
| 36          | Just alphanum                                               | 0-9, A-Z

## Output bases

| Base        | Description                                                 | Symbols                           | Reference
| :--         | :--                                                         | :--                               | :--
| 2           | Binary                                                      | 01
| 8           | Octal                                                       | 01234567
| 10          | Decimal [default]                                           | 0123456789
| 16          | Hexadecimal                                                 | 0123456789ABCDEF
| 26          | Upper-case alphabet                                         | ABCDEFGHIJKLMNOPQRSTUVWXYZ
| 32[r]       | RFC 4648 §6                                                 | ABCDEFGHIJKLMNOPQRSTUVWXYZ234567            | https://www.rfc-editor.org/rfc/rfc4648.html#section-6
| 32h         | RFC 4648 §7 'Base32Hex'                                     | 0123456789ABCDEFGHIJKLMNOPQRSTUV            | https://www.rfc-editor.org/rfc/rfc4648.html#section-7
| 32c         | Crockford's base-32 (0-9, A-Z no I, L, O, U)                | 0123456789ABCDEFGHJKMNPQRSTVWXYZ            | https://en.wikipedia.org/wiki/Base32#Crockford's_Base32
| 32w         | Wordsafe base-32                                            | 23456789CFGHJMPQRVWXcfghjmpqrvwx            | https://en.wikipedia.org/wiki/Base32#Word-safe_alphabet
| 36          | Numbers and upper-case alphabet                             | 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ        | https://en.wikipedia.org/wiki/Base36
| 38hostname  | Valid *nix host and domain name symbols                     | 0123456789abcdefghijklmnopqrstuvwxyz-.
| 39username  | Valid *nix username symbols                                 | 0123456789abcdefghijklmnopqrstuvwxyz-_.
| 45email     | Valid HTML5 email tag symbols                               | 0123456789abcdefghijklmnopqrstuvwxyz-_%+.:@[]
| 48jc1ws     | 32w + unicode symbols                                       | 32w + ʞλμᛎᛏᛘᛯᛝᛦᛨᚠᚧᚬᚼ🜣🜥
| 52          | Both-case alphabetic                                        | A-Z, a-z
| 62          | All alphanum, code point order (hex-style)                  | 0-9, A-Z, a-z                     | https://en.wikipedia.org/wiki/Base62
| 64[r]       | RFC 4648 §5                                                 | A-Z, a-z, 0-9, +, /               | https://www.rfc-editor.org/rfc/rfc4648.html#section-4
| 64u         | RFC 4648 §5; URL-safe                                       | A-Z, a-z, 0-9, -, _               | https://www.rfc-editor.org/rfc/rfc4648.html#section-5
| 64h         | Hex-style base-64                                           | 0-9, A-Z, a-z, -, _
| 64jc1       | Alternate to 64u (base 60 +2 unicode symbols)               | 0-9, A-Z, a-z, ʞ, λ
| 64jc1ws     | 48jc1ws + more unicode symbols                              | 48jc1ws + 🜿🝅▵▸▿◂҂‡±⁑÷∞≈≠ΩƱ
| 128jc1ws    | 64jc1ws + more unicode symbols                              | 64jc1ws + ΞψϠδϟЋЖЯѢф¢£¥§¿ɤʬ⍤⍩⌲⍋⍒⍢ÂĈÊĜĤÎĴÔŜÛŴŶẐâĉêĝĥîĵôŝûŵŷẑÃẼĨÑÕŨỸãẽĩñõũỹÄ
| 128jc1      | Base  64cj1 + more unicode symbols                          | 64cj1 + μᛎᛏᛘᛯᛝᛦᛨᚠᚧᚬᚼ🜣🜥🜿🝅▵▸▿◂҂‡±⁑÷∞≈≠ΩƱΞψϠδϟЋЖЯѢф¢£¥§¿ɤʬ⍤⍩⌲⍋⍒⍢ÂĈÊĜĤÎĴÔŜÛŴ
| 256jc1      | Base 128cj1 + more unicode symbols                          | [many more unicode]
| 288jc1      | Base 256jc1 + more unicode symbols                          | [many more unicode]

## Example output

The chart below shows a big random base 10 number '2023090613425900000000000000001' in various bases.

Example commands to generate output. All of these are equivalent commands:

~~~
convert-base-v1b  2023090613425900000000000000001  128jc1

convert-base-v1b  --ibase 10  2023090613425900000000000000001  128jc1

convert-base-v1b  -to base128jc1  -from base10  2023090613425900000000000000001
~~~

Note that some of the larger bases appear to have longer output - but that's only due to being rendered with proportional fonts, combined with some of the slightly wider (but still single-width) Unicode characters. Look at the "Chars" column to see the actual # of characters in the output.

|Base         | Chars | Number representation
|:--          | --:   | :--
|   2         |   120 | 101111100011011100011110000110110111101101111000011101111110000011011000101110110010001100111110011111111010110100010101
|   8         |    40 | 5743343606675570357603305662147637726425
|__10__       |    36 | __987654321000055555555550000123456789__
|  16         |    30 | BE371E1B7B7877E0D8BB233E7FAD15
|  26         |    26 | EELUTHVVEDOHUKYXZVZLZBWNXL
|  32[r]      |    24 | XY3R4G33PB36BWF3EM7H7LIV
|  32h        |    24 | NORHS6RRF1RU1M5R4CV7VB8L
|  32c        |    24 | QRVHW6VVF1VY1P5V4CZ7ZB8N
|  32w        |    24 | hjqVr8qqQ3qw3g7q6Jx9xHCf
|  36         |    24 | 1L0CRVVUFHZO5Z4EHIOCISK5
|  38hostname |    23 | hdf8q5vjdfxd3t-gwe75u9v
|  39username |    23 | 9v6de929rpvilgdb1gm7o_b
|  45email    |    22 | i:_mxqm7shopf.y02f:75e
|  48jc1ws    |    22 | 6ᚠPv4ᛨHG2ᛘᛯᛘHᚧ9phgμCq7
|  52         |    21 | vNoFHYtcznezzzJbezdYl
|  62         |    21 | 1OvZg4xLjgW5p6V6TBcCT
|  64[r]      |    20 | vjceG3t4d+DYuyM+f60V
|  64u        |    20 | vjceG3t4d-DYuyM-f60V
|  64h        |    20 | lZSU6tjuT-3OkoC-VwqL
|  64j1       |    20 | lZSU6tjuTʞ3OkoCʞVwqL
|  64jc1ws    |    20 | 🜥ᛎrw8‡ᚼ±vΩ5j🜣▵JΩx÷▿f
| 128jc1ws    |    18 | 3ΩqЯδ‡ĤŴŷÛŝ🜣â▸ĨỹĜf
| 128jc1      |    18 | 1ʞRᛨᛘt≠δ⍤Ϡ¿kЖp⍒Û≈L
| 256jc1      |    15 | ítURĴĜÊčȞćZʞŴÁL
| 288jc1      |    15 | aẌňẌỹńÓまĩćaÎɤŸỸ

## Why is the version in the command name

...because of the combination of these factors:

- As with any program dealing with precise numbers, it could be critical to always give identical output, given the same arguments.

- In the future there may be good reasons for the output to change, for given arguments. (And/Or the expected arguments themselves might change.) For example, there are no "official standards" for large bases above 94 as of time of writing, but that could change. And even anything above 16, in most cases is fair game.

- The point above already happened. `v1` already had enough minor issues. For example, it unwisely allowed  the referencing of bases that have no standard or even wide adoption (but might in the future), by number only. It also changed the definition of a couple of custom bases, to be more consistent. (But gave them different names, and relegated the old function names to "*v1compat".

	Those changes broke the user-facing API by definition.

	But it's more than just a semantic version name change. The old version has to still exist on some systems. Hence this can no longer be named `v1`. The "legacy" `v1` will continue to live on.

	But since `v2` is already underway, this can't be named that, so is now `v1b`. (Independent of the standard internal semantic naming convention adhered to.)

## Document history

- 2026-04-26:
	- Updated for v1.0.1 (and v1.0.2).
	- Fixed minor errors in this section.
- 2026-04-25:
	- Updated for v1.0.0
	- Completed "Output Bases" and "Examples" section.
- 2026-04-23: Updated for change to `-v1b`.
- 2026-04-17:
	- Added sections: Input base, and Example output.
	- Removed custom base 94ascii for Output bases (no longer supported).
- 2023-10-09: First version.

## Copyright and license

> Copyright © 2023-2026 Jim Collier (ID: 1cv◂‡Vᛦ)<br>
> Licensed under GNU GPL v2 <https://www.gnu.org/licenses/gpl-2.0.html>. No warranty.
