

declare -a clients=("ucbeda" "uclaclark" "ucm" "ucmppdc" "ucsc" "ucsf" "ucsfmc"
"ucrcmp" 
"this_is_a_failure" )

function check_public_url () {
    echo "URL: http://public.${client}.aspace.cdlib.org"
    wget -q http://public.${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
        echo -e "\033[31mFor ${client} wget exit is $last_exit\033[0m"
        PUBLIC_ERRS+="${client} "
    else
        rm index.html
    fi
}

function check_private_url () {
    echo "URL: https://${client}.aspace.cdlib.org"
    wget -q --no-check-certificate https://${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
        echo -e "\033[31mFor ${client} wget exit is $last_exit\033[0m"
        PRIVATE_ERRS+="${client} "
    else
        rm index.html
    fi
}

PUBLIC_ERRS=()
PRIVATE_ERRS=()
for client in "${clients[@]}"
do
	check_public_url client
	check_private_url client
done
if [ ${#PUBLIC_ERRS[@]} -ne 0 ]; then
    echo -e "\033[31mPUBLIC ERRORS: $PUBLIC_ERRS\033[0m"
fi
if [ ${#PRIVATE_ERRS[@]} -ne 0 ]; then
    echo -e "\033[31mPRIVATE ERRORS: $PRIVATE_ERRS\033[0m"
fi
