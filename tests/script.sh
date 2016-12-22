#!/bin/bash

{ # This ensures the entire script is downloaded

    foo() {
        echo $VERSION
        echo foo $1
    }

    main() {
        foo 1
        foo 2
    }

    if [ "${1}" != "--source-only" ]; then
        main "${@}"
    fi

} # This ensures the entire script is downloaded
