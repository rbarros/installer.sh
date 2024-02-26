#!/bin/bash

{ # This ensures the entire script is downloaded

    version() { echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; }

    foo() {
        echo $VERSION
        echo foo $1
    }

    main() {
        foo 1
        foo 2
	first_version=5.100.2
	second_version=5.1.2
	if [ "$(version "$first_version")" -gt "$(version "$second_version")" ]; then
	     echo "$first_version is greater than $second_version !"
	fi
    }

    if [ "${1}" != "--source-only" ]; then
        main "${@}"
    fi

} # This ensures the entire script is downloaded
