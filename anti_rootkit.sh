#!/bin/sh
# ARK v0.1 - 'A'nti 'R'ootkit 'K'it (c) 2006 Naskel Computer ( http://www.naskel.com/ )
# this script get the latest (september 2006) popular anti rootkit 
# (suck as chkrootkit, rkhunter) and install it
# And add other usefull script to check security, like a open service, open file and mail all infos to root
#
# simply use this command below to install and check your system :
#
# cd /tmp/ && wget http://www.naskel.com/anti_rootkit.sh && sh anti_rootkit.sh 

## latest software
EMAIL="root@naskel.cx"; ## ${USER}"
BASE_PKG="http://www.naskel.com/anti_rootkit/antirkt.tar.gz";
CHKROOTKIT="chkrootkit.tar.gz";
RKHUNTER="rkhunter-1.2.8.tar.gz";
DESTDIR="/etc/admtools";
MAILPROG="mail $EMAIL -s";
ARK_SH="ark.sh";
WGET="wget -q";
BINARIES="/usr/bin/cc /usr/bin/gcc /usr/bin/g++ /usr/bin/c++ /usr/bin/gcc* /usr/bin/g++* /usr/bin/c++* /usr/bin/cpp /usr/bin/cc /usr/bin/cc*";

## safe check
OS=`uname`
if [ "$OS" != "Linux" ]; then
	clear
	echo -e "\nWarning, this script was only tested on linux..\n"
	sleep 5;
	exit 1;
fi

## function
proc_clean() {
	echo -e "\n. Cleaning anti rootkit package...";
	if [ -d "${DESTDIR}/" ]; then
		cd ${DESTDIR}/ && \
		rm -rf ./chkrootkit* && \
		rm -rf ./fc* && \
		rm -f ./${ARK_SH}
	fi

	cd /tmp && \
	rm -rf -- ./chkrootkit* && \
	rm -rf -- ./rkhunter*  && \
	rm -rf -- ./fcheck/  && \
	rm -f -- ./`basename ${BASE_PKG}`
	rm -f -- ./anti_rootkit.sh && return 0
	return 1
}

proc_down() {
	echo -e "\n. Downloading anti rootkit...";
	${WGET} ${BASE_PKG} && return 0
	return 1
}

proc_decomp() {
	echo -e "\n. Decompressing anti rootkit...";
	tar xzfv `basename ${BASE_PKG}` && \
	tar xzfv ${CHKROOTKIT} && \
	tar xzfv ${RKHUNTER} && return 0
	return 1
}

proc_make() {
	echo -e "\n. Compiling anti rootkit...";

	mkdir -p ${DESTDIR}/logs/

	if [ ! -d ${DESTDIR}/ ]; then
		echo "Cant write to destdir: ${DESTDIR}/";
		echo "please make sure you have the right to write to this directory";
		return 1;
	fi
 
	chmod 700 ${DESTDIR}/

	mv /tmp/fcheck ${DESTDIR}/ && \
	mv /tmp/fcheck.cfg ${DESTDIR}/ && \
	chmod 700 ${DESTDIR}/fcheck && \
	chmod 600 ${DESTDIR}/fcheck.cfg

	cd /tmp/ && cd chkrootkit-* && make sense

	## copy directory
	cp -a  /tmp/chkrootkit-* ${DESTDIR}/chkrootkit/

	if [ ! -d "${DESTDIR}/chkrootkit/" ]; then
		echo "invalid directory: ${DESTDIR}/chkrootkit/";
		return 1;
	fi

	cd /tmp/ && \
	cd rkhunter && \
	sh installer.sh && return 0
	return 1
}

## optionnal
proc_chk_sys() {
	#echo -e "\n. To proccess a full scan, please type :";
	#echo "sh ${DESTDIR}/${ARK_SH}";
	echo -e "\n. Generating hash of binaries...";
	${DESTDIR}/fcheck -ca
	echo -e "\n. Proccessing a full scan, please wait.";
	cd ${DESTDIR}/chkrootkit/
	./chkrootkit
	cd ${DESTDIR}
	echo -e "\n. Proccessing interactive scan, please read carrefully :";
	/usr/local/bin/rkhunter -c
	echo -e "\n. Checking binary integrity :"
	${DESTDIR}/fcheck -a
	echo -e "\n. Listing service: "
	echo    "-----------------------"
	netstat -na | grep LISTEN
	echo -e "\n. Listing open file: "
	echo    "-----------------------"
	lsof -i | grep ESTABLISHED
	echo -e "\n. Echo listing tmp directory :"
	echo    "------------------------------"
	ls -ail /tmp/
	return 0;
}

proc_script() {
echo -e "\n. Creating cron job script..."
cat << EOF > ${DESTDIR}/${ARK_SH} 
#!/bin/sh
# ARK v0.1 - 'A'nti 'R'ootkit 'K'it (c) 2006 Naskel Computer ( http://www.naskel.com/ )
# this script get the latest (september 2006) popular anti rootkit 
# (suck as chkrootkit, rkhunter) and install it
# And add other usefull script to check security, like a open service, open file and mail all infos to root
#
# simply use this command below to install and check your system :
#
# cd /tmp/ && wget http://www.naskel.com/anti_rootkit.sh && sh anti_rootkit.sh 
echo ""
echo "ARK v0.1 - 'A'nti 'R'ootkit 'K'it (c) 2006 Naskel Computer - http://www.naskel.com/"
echo ""
echo ". Scan START :"
echo "--------------"

cd ${DESTDIR}/chkrootkit/
./chkrootkit
/usr/local/bin/rkhunter -c --cronjob
echo -e "\nChecking binary integrity :"
./fcheck -a
echo -e "\n. Listing service: "
echo    "-----------------------"
netstat -na | grep LISTEN
echo -e "\n. Listing open file: "
echo    "-----------------------"
lsof -i | grep ESTABLISHED
echo -e "\nEcho listing tmp directory :"
echo    "------------------------------"
ls -ail /tmp/
echo ""
echo ". Scan Finished"
echo "----------------"
EOF
chmod +x ${DESTDIR}/${ARK_SH} 
}

proc_postinstall() {
	echo -e "\n. Cleaning tmp package...";
	cd /tmp
	rm -rf -- ./chkrootkit*
	rm -rf -- ./rkhunter*
	rm -f -- ./`basename ${BASE_PKG}`
	rm -f -- ./anti_rootkit.sh

	echo ""
	echo -e "\n. Please install this crontab :";
	echo "0 3 * * * sh ${DESTDIR}/${ARK_SH} 2>&1 | ${MAILPROG} \"Security Scan for host `hostname`\"";
	echo ""
	return 0
}

proc_protect_compilo() {
	echo -e "\n. Changing right of compiler to 0700";
	chmod 700 `echo ${BINARIES}` > /dev/null
	return 0
}

## go to /tmp
cd /tmp && proc_protect_compilo && proc_clean && proc_down && proc_decomp && proc_make && \
proc_chk_sys && proc_script && proc_postinstall && echo -e "\nAll done." && exit 0

echo 'Something is bad with your path or network, we cant install chkrootkit or rkhunter.';
exit 1

