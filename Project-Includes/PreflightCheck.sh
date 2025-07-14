#!/bin/bash

function PreflightCheck()
{

export curr_user="$USER"
export user_check

user_check="$(echo "$curr_user" | grep -c root)"


if [ $user_check -ne 1 ]; then
    print_error "Must run as root."
    error_out
fi

echo "All checks passed...."

}
