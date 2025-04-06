#!/usr/bin/env bash

# https://github.com/lincheney/dsv/blob/main/make-completions.sh
set -eu -o pipefail
cd "$(dirname "$0")"
prog=csi
mkdir -p completions/
for shell in bash zsh; do
    output="$(PYTHONPATH= shtab --shell="$shell" csi.make_main_parser --error-unimportable --prog "$prog")"
    if ! diff completions/"$prog"."$shell" <(echo "$output"); then
        echo "$output" >completions/"$prog"."$shell"
    fi
done
