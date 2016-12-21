#!/bin/bash

{ # This ensures the entire script is downloaded

    echo -e "|   Downloading script.sh to /tmp/script.sh\n|\n|   + $(wget -nv -o /dev/stdout -O /tmp/script.sh --no-check-certificate https://raw.github.com/rbarros/installer.sh/dev/tests/script.sh)"

if [ -f /tmp/script.sh ]
then
    . /tmp/script.sh --source-only
    foo 3
else
    # Show error
    echo -e "|\n|   Error: The script could not be downloaded\n|"
fi

} # This ensures the entire script is downloaded
