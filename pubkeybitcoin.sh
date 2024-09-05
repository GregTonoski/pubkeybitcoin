#!/usr/bin/env sh

# NAME
#    pubkeybitcoin - calculate a secp256k1 public key from a private key.
#
# EXAMPLES
#    sh pubkeybitcoin.sh -f hex FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140
#    sh pubkeybitcoin.sh -f sylui < file.txt
#    sh pubkeybitcoin.sh $( xxd -r -p file.bin )
#    xargs -a privkeys_list.txt -p -o -L 1 sh pubkeybitcoin.sh
#    while read row ; do sh pubkeybitcoin.sh ${row} < /dev/null ; done < privkeys_list.txt ; sh pubkeybitcoin.sh ${row}
#    od -x -A n -w32 file.bin | sh pubkeybitcoin.sh
#    hexdump -v -e '16/1 "%02x " "\n"' file.bin | sh pubkeybitcoin.sh

export LC_ALL=C
pubkeybitcoin_version="1.0.0"
release_date="20240828T144000Z"

priv_key=""

fn_show_helptext () {
  printf "Usage: sh pubkeybitcoin.sh [OPTION] [PRIVATE_KEY]\n"
  printf "    pubkeybitcoin - calculate a secp256k1 public key from a private key and print it to standard output.\n"
  printf "\n"
  printf "With no PRIVATE_KEY or when PRIVATE_KEY is -, read standard input.\n\n"
  printf "  -f, --from={hex|sylui|wif}    encoding of private key \n"
  printf "  -h, --help                    display this help and exit\n"
  printf "  -v, --version                 display version information and exit\n"
  printf "\n"
  printf "Pubkeybitcoin uses bc calculator and stops execution with an error message if it is not installed on the system.\n"
  printf "\n"
  printf "Examples:\n"
  printf "  sh pubkeybitcoin.sh --from=sylui FUFEXU DAZOWI WARICI TEVYWO RUDITA CYSALU LEHAXA CONURA SAFYA JYZATO XORUZI MEQOLE XA\n"
  printf "  sh pubkeybitcoin.sh -f hex FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140\n"
  printf "  sh pubkeybitcoin.sh -f wif L5oLkpV3aqBjhki6LmvChTCV6odsp4SXM6FfU2Gppt5kFLaHLuZ9\n"
  printf "\nThis is the %s version. Release date: %s. Author: Greg Tonoski <greg.tonoski@gmail.com>." "${pubkeybitcoin_version}" "${release_date}"
}

fn_show_version () {
  printf "pubkeybitcoin %s \n" "${pubkeybitcoin_version}"
}

fn_purge_of_whitespaces () {
  line_of_text="${*}"
  line_of_text="${line_of_text#${line_of_text%%[![:space:]]*}}" line_of_text="${line_of_text%${line_of_text##*[![:space:]]}}"
  while [ "${line_of_text#*[[:space:]]}" != "${line_of_text}" ] ; do
    line_of_text="${line_of_text%%[[:space:]]*}""${line_of_text#*[[:space:]]}"
  done
  printf "%s" "${line_of_text}"
}

fn_validate_user_input () {
  input_string="${*}"
  case "${input_string}" in
    --help | -h ) fn_show_helptext ; exit 0 ;;
    --version | -v ) fn_show_version ; exit 0 ;;
    *[![:xdigit:][:alpha:][:space:]-=]* ) echo "ERROR. There was a non-alphanumeric character entered." >&2 ; exit 1;;
    *-?*-* ) echo "ERROR. There were more than one options (dash character \"-\") entered." >&2 ; exit 1;;
    "${input_string##*[![:space:]]*}" | - ) return 0 ;;
    "--from=hex"* | "-f hex"* ) opt_from="hex" priv_key="${input_string#*-f*[[:space:]=]*hex}" ;;
    *"--from=hex" | *"-f hex" ) opt_from="hex" priv_key="${input_string%[[:space:]]-f*[[:space:]=]*hex}" ;;
    "--from=sylui"* | "-f sylui"* ) opt_from="sylui" priv_key="${input_string#*-f*[[:space:]=]*sylui}" ;;
    *"--from=sylui" | *"-f sylui" ) opt_from="sylui" priv_key="${input_string%[[:space:]]-f*[[:space:]=]*sylui}" ;;
    "--from=wif"* | "-f wif"* ) opt_from="wif" priv_key="${input_string#*-f*[[:space:]=]*wif}" ;;
    *"--from=wif" | *"-f wif" ) opt_from="wif" priv_key="${input_string%[[:space:]]-f*[[:space:]=]*wif}" ;;
    *-[![:space:]]* ) echo "ERROR. Unrecognized or misplaced option was entered." >&2 ; exit 1 ;;
    "${input_string##*[![:xdigit:][:space:]]*}" | "${input_string##*0x[![:xdigit:][:space:]]*}" ) priv_key="${input_string}" ;;
    * ) echo "ERROR. Invalid format of user input. An option may have not been entered. Use -help option for more information." >&2 ; exit 1 ;;
  esac
  if [ "${opt_from:-hex}" = "hex" ] ; then
    priv_key="${priv_key#${priv_key%%[![:space:]]*}}"
    priv_key="${priv_key#0[xX]}"
    case "${priv_key}" in
      *[![:xdigit:][:space:]]* ) echo "ERROR. There was a non-hexadecimal digit character entered." >&2 ; exit 1;;
      * ) ;;
    esac
    
    priv_key=$( fn_purge_of_whitespaces "${priv_key}" )
    if [ "${#priv_key}" -gt 64 ] ; then
      echo "ERROR. There were more than 64 hexadecimal digits entered." >&2 ; exit 1
    elif [ "${#priv_key}" -lt 64 ] ; then
      echo "WARNING. There were ${#priv_key} hexadecimal digits entered. It is fewer than typical 64 ones for secp256k1 private key. Are you sure that the entered number is correct?"
      read any_variable
    fi
  elif [ "${opt_from}" = "sylui" ] ; then
    case "${priv_key}" in
      *[![:alpha:][:space:]]* ) echo "ERROR. There was a non-latin letter entered." >&2 ; exit 1;;
      * ) ;;
    esac
    priv_key=$( fn_purge_of_whitespaces "${priv_key}" )
    if [ "${#priv_key}" -gt 74 ] ; then
      echo "ERROR. There were more than 74 characters entered and it is too many." >&2 ; exit 1
    fi
  elif [ "${opt_from}" = "wif" ] ; then
    case "${priv_key}" in
      *[![1-9A-HJ-NP-Za-km-z][:space:]]* ) echo "ERROR. There was a non-base58 letter entered." >&2 ; exit 1;;
      * ) ;;
    esac
    priv_key=$( fn_purge_of_whitespaces "${priv_key}" )
    if [ "${#priv_key}" -gt 52 ] ; then
      echo "ERROR. There were more than 52 characters entered and it is too many." >&2 ; exit 1
    elif [ "${#priv_key}" -lt 52 ] ; then
      echo "ERROR. There were fewer than 50 characters entered and it is too few." >&2 ; exit 1
    fi
  fi
}

fn_to_uppercase () {
  ascii_value=0
  substring_of_non_lowercase_chars="${1%%${1#[![:lower:]]}}" # ABCdefg123 -> 1%%defg123 = ABC
  substring_with_lowercase_chars="${1#${substring_of_non_lowercase_chars}}"
  chars_separated_with_spaces=""
  while [ "${substring_with_lowercase_chars}" ] ; do
    chars_separated_with_spaces="${chars_separated_with_spaces}""\'""${substring_with_lowercase_chars%%${substring_with_lowercase_chars#?}} "
    substring_with_lowercase_chars="${substring_with_lowercase_chars#?}"
  done
  eval set -- ${chars_separated_with_spaces}
  set -- $(printf "%d " "${@}" )
  while [ "${1}" ] ; do
    if [ "${1}" -ge 97 ] && [ "${1}" -le 122 ] ; then # if lower case then change to upper case
      string_dec="${string_dec}"" "$(( ${1} - 32 ))
    else
      string_dec="${string_dec}"" ""${1}"
    fi
  shift 1
  done
  eval set -- ${string_dec}
  set -- $( printf "\\%03o" "${@}" )
  printf "%s" "${substring_of_non_lowercase_chars}"
  printf "${*}"
}

fn_sylui_to_hex () {
  vowels="AEIOUY"
  consonants="BCDFGHJKLMNPQRSTVWXZ"
  
  i=0
  string_of_chars="${vowels}"
  while [ "${string_of_chars}" ] ; do
    eval VOWEL_"${string_of_chars%%${string_of_chars#?}}"="${i}" # i.e. VOWEL_A=0 and so on
    i=$(( i + 1 ))
    string_of_chars="${string_of_chars#?}"
  done
  vowels_count="${i}"
  string_of_chars="${consonants}"
  while [ "${string_of_chars}" ] ; do
    eval CONSONANT_"${string_of_chars%%${string_of_chars#?}}"="${i}" # i.e. CONSONANT_B=6 and so on
    i=$(( i + 1 ))
    string_of_chars="${string_of_chars#?}"
  done

  sylui_string="${*}"
  augend=""
  coefficient=0
  character=""
  coefficients_string=""
  while [ "${sylui_string}" ] ; do
    character="${sylui_string%%${sylui_string#?}}"
    case "${character}" in
      ["${vowels}"] ) eval 'coefficient=$(( ( '${augend}' + ${VOWEL_'"${character}"'} ) ))' ; coefficients_string="${coefficients_string}"" ${coefficient}" ; augend="" ;; # e.g. coefficient=$(( "${augend}" + "${VOWEL_A}" ))
      ["${consonants}"]) if [ ! "${augend}" ] ; then
          eval 'augend=$(( ( ${CONSONANT_'"${character}"'} - '"${#vowels}"' + 1 ) * '"${#vowels}"' ))' # e.g. augend=$(( ( "${CONSONANT_B} - ${#vowels} ) * ${#vowels} ))
        else
          echo "ERROR. There was incorrect SylUI code entered." >&2 ; return 1
        fi
      ;;
      *) echo "ERROR." >&2 ; return 2 ;;
    esac
    sylui_string="${sylui_string#?}"
  done
  
  base=$(( ${#vowels} * ${#consonants} + ${#vowels} ))
  exponent=0
  bc_expression="0"
  while [ "${coefficients_string}" ] ; do
    coefficient="${coefficients_string##${coefficients_string%[[:space:]]*}[[:space:]]}"
    bc_expression="${coefficient}"'*'"${base}"'^'"${exponent}"' + '"${bc_expression}"
    exponent=$(( ${exponent} + 1 ))
    coefficients_string="${coefficients_string%%[[:space:]]${coefficient}}"
  done
  echo "obase=16; ${bc_expression}" | bc
}

fn_decode_privkey_from_wif () {
  input_substring="${*}"
  parsed_string=""
  string_dec58=""
  dec58=0
  while [ "${input_substring}" ] ; do
    parsed_string="${parsed_string}""\'""${input_substring%%${input_substring#?}}"" "
    input_substring="${input_substring#?}"
  done
  eval set -- ${parsed_string}
  set -- $( printf "%d " "${@}" )
  subtrahend=0
  while [ "${1}" ] ; do
    case "${1}" in
      49 | [5][0-7] ) subtrahend=49 ;;
      [6][5-9] | 7[0-2] ) subtrahend=56 ;;
      7[4-8] ) subtrahend=57 ;;
      8[0-9] | 90 ) subtrahend=58 ;;
      9[7-9] | 10[0-7] ) subtrahend=64 ;;
      109 | 11[0-9] | 12[0-2] ) subtrahend=65 ;;
      * )  echo "ERROR. Unexpected error." >&2 ; exit 1 ;;
    esac
    dec58=$(( ${1} - ${subtrahend} ))
    string_dec58="${string_dec58}"" ${dec58}"
    shift 1
  done
  if command -v bc >/dev/null ; then
    bc_expression="0"
    exponent=0
    result_hex_number=""
    while [ "${string_dec58}" ] ; do
      bc_expression="${string_dec58##${string_dec58%[[:space:]]*[[:digit:]]}}""*58^""${exponent}""+""${bc_expression}"
      string_dec58="${string_dec58%[[:space:]]*[[:digit:]]}"
      exponent=$(( ${exponent} + 1 ))
    done
    printf "obase=16; ${bc_expression}\n" | BC_LINE_LENGTH=0 bc | { read result_hex_number ; printf "%.64s\n" "${result_hex_number#??}" ; }
  else
    eval set -- ${string_dec58}
    quotient=""
    reminder=0
    result_number=""
    
    while [ "${1}" ] ; do
      quotient=""
      reminder=0
      while [ "${1}" ] ; do
        quotient_digit=$(( ( ${reminder} * 58 + ${1} ) / 256 ))
        quotient="${quotient}"" ""${quotient_digit}"
        reminder=$(( ( ${reminder} * 58 + ${1} ) % 256 ))
        shift 1
      done
      result_number="${reminder}"" ""${result_number}"
      while [ "${quotient#[[:space:]]0}" != "${quotient}" ] ; do # delete leading zeros
          quotient="${quotient#[[:space:]]0}"
        done
      eval set -- ${quotient}
    done
    set -- $( printf "%s " ${result_number} )
    result_hex_number=$( printf "%02X" "${@}" )
    printf "%.64s\n" "${result_hex_number#??}"
  fi
}

### Beginning of the program execution ###

if ! command -v bc >/dev/null ; then
  if ! command -v bc-gh >/dev/null ; then
    echo "ERROR. There isn't the calculator program bc found in the system. This program can't continue without the bc which is widely available at no cost and its source is open, e.g. https://git.gavinhoward.com/gavin/bc/releases". >&2 ; exit 3
  else
    bc_name="bc-gh"
  fi
fi

if fn_validate_user_input "${*}" ; then
  if [ -z "${priv_key}" ] ; then
    printf "Enter private key that will be used to calculate the corresponding secp256k1 public key:\n"
    read user_input_string
    fn_validate_user_input "${user_input_string}"
    if [ -z "${priv_key}" ] ; then
      printf "ERROR. There wasn't anything read from user input.\n" >&2
      exit 1
    fi
  fi
fi

if [ "${opt_from}" = "wif" ] ; then
  priv_key=$( fn_decode_privkey_from_wif ${priv_key} )
fi
if ! [ "${priv_key##*[[:lower:]]*}" ] ; then
  priv_key=$( fn_to_uppercase ${priv_key} )
fi
if [ "${opt_from}" = "sylui" ] ; then
  priv_key=$( fn_sylui_to_hex "${priv_key}" )
  if [ ! $? ] ; then exit 1; fi
fi
priv_key="${priv_key#${priv_key%%[!0]*}}" # remove leading zeros
if ! [ "${priv_key}" ] ; then
  echo "ERROR. The entered value is 0." >&2 ; exit 2
fi

if [ "${#priv_key}" -eq 64 ] ; then
  string_of_hex_priv_key="${priv_key}"
  string_of_hex_secp256k1_limit="FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140"
  while [ "${string_of_hex_priv_key}" ] ; do
    hex_digit_pair_priv_key="${string_of_hex_priv_key%%${string_of_hex_priv_key#??}}"
    hex_digit_pair_secp256k1_limit="${string_of_hex_secp256k1_limit%%${string_of_hex_secp256k1_limit#??}}"
    if [ $(( 0x${hex_digit_pair_priv_key} )) -lt $(( 0x${hex_digit_pair_secp256k1_limit} )) ] ; then
      break
    elif [ $(( 0x${hex_digit_pair_priv_key} )) -gt $(( 0x${hex_digit_pair_secp256k1_limit} )) ] ; then
      echo "ERROR. The entered value exceeds the limit for secp256k1 private key: FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140." >&2 ; exit 2
    fi
    string_of_hex_priv_key="${string_of_hex_priv_key#??}"
    string_of_hex_secp256k1_limit="${string_of_hex_secp256k1_limit#??}"
  done
fi

if [ "${priv_key##*[0123456789ABCDEF]*}" ] ; then
  echo "ERROR. Unexpectedly, the value of the priv_key variable contains non-hexadecimal or lower-case digit despite sanitization. Program execution interrupted." >&2 ; exit 4
fi
BC_LINE_LENGTH=0 ${bc_name:-bc} <<-EOF

ibase=16
obase=10 /* here the value 10 is not decimal but hexadecimal 0x10 */
scale=0

p=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
genpx=79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
genpy=483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
a=0
b=7
k_limit=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140

define modulo (signedinteger, divisor) {
  if ( signedinteger < 0 ) {
    return ( ((signedinteger % divisor) + divisor) % divisor )
  }
  return ( signedinteger % divisor )
}

define mod_inverse (a, modulus) {
  auto q, prevy, y, m, temp
  y = 1
  m = modulus
  a = modulo (a, m)
  while (a > 1) {
    q = m / a
    temp = y
    y = prevy - (q * y)
    prevy = temp
    temp = a
    a = m % a
    m = temp
  }
  return ( modulo(y, modulus) )
}

define sloped (x, y, p) {
  return ( modulo((3 * x ^ 2 + a) * mod_inverse((2 * y), p), p) )
}

define doublex (x, y, p) {
  return ( modulo(sloped(x, y, p) ^ 2 - (2 * x), p) )
}

define doubley (x, xx, y, p) {
  return ( modulo(sloped(x, y, p) * (x - xx) - y, p) )
}

define slopea (x1, x2, y1, y2) {
  return ( modulo((y1 - y2) * mod_inverse(x1 - x2, p), p) )
}

define addx (x1, y1, x2, y2) {
  if (x1 == x2) {
    if (y1 == y2) {
      return ( doublex(x1, y1, p) )
    }
  }
  return ( modulo( slopea(x1, x2, y1, y2)^2 - x1 - x2, p) )
}

define addy (x1, x1x, y1, x2, y2) {
  if (x1 == x2) {
    if (y1 == y2) {
      return ( doubley(x1, doublex (x1, y1, p), y1, p) )
    }
  }
  return ( modulo((slopea(x1, x2, y1, y2) * (x1 - x1x) - y1 ), p) )
}

define show_leading_zeros (num, max) {
  i = obase
  while ( num * i < max ) {
   "0"
   i = i * obase
   }
  return (num)
}

define multiply(k, genpx, genpy) {
  auto divisor, dividend, exponent, i, pubkeyxlast, pubkeyx, pubkeyy, quotient
  divisor=2
  dividend=k
  exponent=0
    while (dividend/divisor) {
      divisor=divisor*2
      exponent=exponent+1
    }
  pubkeyx=genpx
  pubkeyy=genpy
  for (i=0; i < exponent; i++) {
    pubkeyxlast = pubkeyx
    pubkeyx = doublex(pubkeyx, pubkeyy, p)
    pubkeyy = doubley(pubkeyxlast, pubkeyx, pubkeyy, p)
    quotient=(k%(2^(exponent-i)))/(2^(exponent-1-i))
    if (quotient) {
      pubkeyxlast = pubkeyx
      pubkeyx = addx(pubkeyx, pubkeyy, genpx, genpy)
      pubkeyy = addy(pubkeyxlast, pubkeyx, pubkeyy, genpx, genpy)
    }
  }
/*  "Uncompressed format of pubkey:
"
  "04"
  if ( obase == 10 ) (show_leading_zeros(pubkeyx*2^100 + pubkeyy, p*2^100))
  if ( obase != 10 ) {
    pubkeyx; pubkeyy
  }
*/
  "secp256k1 pubkey:
"
  if ( pubkeyy%2 ) {
    "03"
    return ( show_leading_zeros(pubkeyx, p) )
  }
  "02"
  return ( show_leading_zeros(pubkeyx, p) )
}

define input_validation(k) {
  if ( k == 0 ) {
    "ERROR. Input of privkey value unsuccessful. Expected format (case
   sensitive):
  k=FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140"
  return (0)
  }
  if ( k > k_limit ) {
    "ERROR. Entered value of private key exceeds secp256k1 limit."
    return (0)
  }
  return (1)
}

privkey=${priv_key}
if ( input_validation(privkey) ) {
  multiply(privkey, genpx, genpy)
}
/* Author: greg.tonoski@gmail.com */
EOF
