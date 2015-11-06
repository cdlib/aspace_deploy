

declare -a clients=("ucbeda" "uclaclark" "ucm" "ucmppdc" "ucsc" "ucsf" "ucsfmc"
"ucrcmp" )
PUBLIC_ERRS=()
PRIVATE_ERRS=()
for client in "${clients[@]}"
do
    echo "URL: http://public.${client}.aspace.cdlib.org"
    wget -q http://public.${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
        echo -e "\033[35mFor ${client} wget exit is $last_exit\033[0m"
        PUBLIC_ERRS+="${client} "
    else
        rm index.html
    fi
    echo "URL: https://${client}.aspace.cdlib.org"
    wget -q --no-check-certificate https://${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
        echo -e "\033[35mFor ${client} wget exit is $last_exit\033[0m"
        PRIVATE_ERRS+="${client} "
    else
        rm index.html
    fi
done
if [ ${#PUBLIC_ERRS[@]} -ne 0 ]; then
    echo -e "\033[35mPUBLIC ERRS: $PUBLIC_ERRS\033[0m"
fi
if [ ${#PRIVATE_ERRS[@]} -ne 0 ]; then
    echo -e "\033[35mPRIVATE ERRS: $PRIVATE_ERRS\033[0m"
fi
