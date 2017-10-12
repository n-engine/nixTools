#!/bin/bash

## test if argument is correct
if [ "$1" = "" ]; then
        exit 1;
fi

TARGET="$1";
AUSER="/var/abus/${TARGET}.user";
COUNT=0;
DEBUG="0";
SYSLOG="1";
MAIL="naskel@gmail.com";

Log()
{
	if [ ${DEBUG} = "1" ]; then
		echo "`date '+%d %B %H:%m'` [warning] abus: $*";
	fi
	if [ ${SYSLOG} = "1" ]; then
		echo "`date '+%d %B %H:%m'` [warning] abus: $*" >> /var/log/messages;
	fi
}

## check if user exist
if [ -f "${AUSER}" ]; then
	COUNT=`cat ${AUSER}`;
	COUNT=$(( ${COUNT} + 1));
	echo "${COUNT}" > "$AUSER";
else
	echo "unknow file: $AUSER";
	## create new user
	echo 1 > "$AUSER";
	COUNT=1;
fi

## check if user tested more than 3 times
if [ ${COUNT} -gt 3 ]; then
	Log "new user (${TARGET}) added to reject";
	echo "sorry this is a private box, your ip is logged and reported to your provider as a abus.";
	/sbin/route add -host ${TARGET} reject;
	echo -e "new route added to reject : ${TARGET}" | mail -s "Abus with user ${TARGET}" ${MAIL}
else
	Log "user(${AUSER}) tested(${COUNT})";
fi

exit 0;

## all ok
