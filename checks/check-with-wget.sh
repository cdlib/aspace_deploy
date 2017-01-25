
silent=0

function usage () {
	echo "check-with-wget.sh (-s for silent operation) (-h for this msg)"
}

while getopts hs FLAG; do
	case $FLAG in
		s)
			silent=1
			;;
		h)
			usage
			exit 0
			;;
	esac
done

declare -a clients=("ucbeda" "uclaclark" "ucm" "ucmppdc" "ucsc" "ucsf" "ucrcmp" )

function check_public_url () {
	if [ $silent -ne 1 ] ; then
		echo "URL: http://public.${client}.aspace.cdlib.org"
	fi
    wget --timeout=10 -q http://public.${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
		if [ $silent -ne 1 ] ; then
			echo -e "\033[31mFor ${client} wget exit is $last_exit\033[0m"
		fi
        PUBLIC_ERRS+="${client} "
    else
        rm index.html
    fi
}

function check_private_url () {
	if [ $silent -ne 1 ] ; then
		echo "URL: https://${client}.aspace.cdlib.org"
	fi
    wget --timeout=10 -q --no-check-certificate https://${client}.aspace.cdlib.org > /dev/null
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
		if [ $silent -ne 1 ] ; then
			echo -e "\033[31mFor ${client} wget exit is $last_exit\033[0m"
	    fi
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
if [ $silent -ne 1 ] ; then
	if [ ${#PUBLIC_ERRS[@]} -ne 0 ]; then
		echo -e "\033[31mPUBLIC ERRORS: $PUBLIC_ERRS\033[0m"
	fi
	if [ ${#PRIVATE_ERRS[@]} -ne 0 ]; then
		echo -e "\033[31mPRIVATE ERRORS: $PRIVATE_ERRS\033[0m"
	fi
fi
if [ ${#PRIVATE_ERRS[@]} -ne 0 ]; then
	exit 11
fi
if [ ${#PUBLIC_ERRS[@]} -ne 0 ]; then
	exit 12
fi
