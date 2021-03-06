
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

declare -a clients=("ucbeda" "uci" "uclaclark" "uclacsrc" "ucm" "ucmppdc" "ucrcmp" "ucsc" "ucsf" "bogus")

function check_public_url () {
	if [ $silent -ne 1 ] ; then
		echo "URL: http://public.${client}.aspace.cdlib.org"
	fi
    wget --timeout=10 --quiet -O /dev/null http://public.${client}.aspace.cdlib.org
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
		if [ $silent -ne 1 ] ; then
			echo -e "\033[31mFor ${client} public wget exit is $last_exit\033[0m"
		fi
        PUBLIC_ERRS+="${client} "
	fi
}

function check_private_url () {
	if [ $silent -ne 1 ] ; then
		echo "URL: https://${client}.aspace.cdlib.org"
	fi
    wget --timeout=10 --quiet -O /dev/null https://${client}.aspace.cdlib.org
    last_exit=$?
    if [ $last_exit -ne 0 ] ; then
		if [ $silent -ne 1 ] ; then
			echo -e "\033[31mFor ${client} private wget exit is $last_exit\033[0m"
	    fi
        PRIVATE_ERRS+="${client} "
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
