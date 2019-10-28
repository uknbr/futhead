#  futhead.sh
#  
#  Copyright 2016 Pedro Pavan <pedro.pavan@linuxmail.org>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  
#!/usr/bin/env bash
#===============================================================
# Changes history:
#
#  Date     |    By       |  Changes/New features
# ----------+-------------+-------------------------------------
# Pedro	      01-23-2016    Initial release
# Pedro	      07-15-2017    Adapted for FIFA17
#===============================================================

# =======================
#  Configuration
# =======================
TOTAL_PAGES=2
START_PAGE=1
WAIT_TIME=2
AVG_PARSER=12

# =======================
#  Variables
# =======================
WWWDUMP="lynx -dump -nolist -width=300 -accept_all_cookies -display_charset=UTF-8"
WWWURL="http://www.futhead.com/17/players/?page"
WWWDATA="$(mktemp futhead.tmp.XXXXXXXXXX)"
WWWFILTER="^GK|^CB|^RB|^LB|^RWB|^LWB|^CDM|^CM|^RM|^LM|^CAM|^RW|^LW|^CF|^ST"
#WWWFILTER="^CB"

TMP_OUTPUT="$(mktemp futhead.tmp.XXXXXXXXXX)"
TMP_LINE="$(mktemp futhead.tmp.XXXXXXXXXX)"
TMP_PAGE="$(mktemp futhead.tmp.XXXXXXXXXX)"
TMP_WWW="$(mktemp futhead.tmp.XXXXXXXXXX)"

FILE_SQL="futhead_${START_PAGE}-${TOTAL_PAGES}.sql"
FILE_LOG="futhead_${START_PAGE}-${TOTAL_PAGES}.log"
> ${FILE_SQL}
> ${FILE_LOG}

# =======================
#  Remove temporary files
# =======================
CleanTemp() {
	rm -f futhead.tmp.*
}

# =======================
#  Border
# =======================
Border() {
	TYPE=$1
	TIME=$(date '+%F %T')
	NEWLINE="?"
	
	echo -e "================================"
	echo -e "  ${TYPE} time - ${TIME}"
	echo -e "================================"
	
	[ "${TYPE}" == "Start" ] && NEWLINE="\n" || NEWLINE=""
	echo -e "${NEWLINE}***************** $(basename $0) [${TIME}] *****************" >> ${FILE_LOG}
}

# =======================
#  Exit
# =======================
Exit_Script() {
	EXIT_CODE=$1
	
	#CleanTemp
	Border "Finish"
	exit ${EXIT_CODE}
}

# =======================
#  Message
# =======================
Message() {
	MSG_TYPE="$1"
	MSG="$2"
	
	case "${MSG_TYPE}" in
		"-info")	echo -e "[+] ${MSG}" | tee -a ${FILE_LOG}	;;
		"-fail")	echo -e "[!] ${MSG}" | tee -a ${FILE_LOG}	;;
		"-more")	echo -e "[*] ${MSG}" | tee -a ${FILE_LOG}	;;
		      *)	echo -e "[-] ${MSG}" | tee -a ${FILE_LOG}	;;
	esac
}

# =======================
#  Check status
# =======================
Check_Status() {
	if [ $? -ne 0 ]; then
		Message -fail "Previus command failed!"
		Exit_Script 5
	fi
}

# =======================
#  Main
# =======================
Border "Start"

if [ ${START_PAGE} -eq 1 ]; then
	echo "-- Starting" >> ${FILE_SQL}
	echo "TRUNCATE TABLE \`player\`;" >> ${FILE_SQL}
fi

for page in $(seq ${START_PAGE} ${TOTAL_PAGES}); do

	# starting
	Message -info "Loading (${page}/${TOTAL_PAGES}) - $(expr $(expr $(expr ${AVG_PARSER} + ${WAIT_TIME}) \* $(expr ${TOTAL_PAGES} - ${page})) / 60) minutes left"
	echo -e "\n-- Page ${page}" >> ${FILE_SQL}
	
	# to avoid problems (security)
	sleep ${WAIT_TIME}
	
	# fetch data
	TARGET_URL="${WWWURL}=${page}"
	#${WWWDUMP} ${TARGET_URL} > ${TMP_WWW}
	${WWWDUMP} ${TARGET_URL} | tee -a ${TMP_WWW}
	Check_Status	
	cat ${TMP_WWW} | sed -e 's/^[ \t]*//' | egrep -B 2 "${WWWFILTER}" | egrep -v '^-' | egrep -v '^\[' > ${WWWDATA}
	
	# fetch data (again)
	curl ${TARGET_URL} 2> /dev/null > ${TMP_PAGE}
	Check_Status
	> ${TMP_OUTPUT}

	# parser
	for line in $(seq 1 3 999999); do
		sed -n "${line},+2p" ${WWWDATA} > ${TMP_LINE}
		
		if [ -s ${TMP_LINE} ]; then
			cat ${TMP_LINE} | tr '\n' ';' | rev | cut -c 2- | rev >> ${TMP_OUTPUT}
		else
			break
		fi
	done

	while read line; do
		PLAYER_NAME="$(echo ${line} | cut -d ';' -f 1)"
		PLAYER_TEAM="$(echo ${line} | cut -d ';' -f 2 | cut -d '|' -f 1 | sed -e 's/^[ \t]*//')"
		PLAYER_LEAGUE="$(echo ${line} | cut -d ';' -f 2 | cut -d '|' -f 2 | sed -e 's/^[ \t]*//')"
		PLAYER_POSITION="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 1)"
		PLAYER_OVE="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 2)"
		PLAYER_POT="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 3)"
		PLAYER_GRO="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 4)"
		PLAYER_AGE="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 5)"
		PLAYER_CONTRACT="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 10)"
		PLAYER_LIKE="$(echo ${line} | cut -d ';' -f 3 | cut -d ' ' -f 11)"
		PLAYER_LINK="http://www.futhead.com$(grep -B 5 "${PLAYER_NAME}" ${TMP_PAGE} | grep 'career-mode/players' | cut -d '"' -f 2)"
		
		# LOG section
		echo "
======================================
+ PAG:	${page}
+ NAME:	${PLAYER_NAME}
+ TEAM:	${PLAYER_TEAM}
+ LEG:	${PLAYER_LEAGUE}
+ POS:	${PLAYER_POSITION}
+ RAT:	${PLAYER_OVE}
+ POT:	${PLAYER_POT}
+ GRO:	${PLAYER_GRO}
+ AGE:	${PLAYER_AGE}
+ CON:	${PLAYER_CONTRACT}
+ LIKE:	${PLAYER_LIKE}
+ URL:	${PLAYER_LINK}
======================================" >> ${FILE_LOG}

		# SQL Section
		echo "INSERT INTO \`player\` (\`page\`, \`name\`, \`team\`, \`league\`, \`position\`, \`rating\`, \`potential\`, \`growth\`, \`age\`, \`contract\`, \`like\`, \`url\`) VALUES ('${page}', '$(echo ${PLAYER_NAME} | sed -e s/\'/./g)', '$(echo ${PLAYER_TEAM} | sed -e s/\'/./g)', '$(echo ${PLAYER_LEAGUE} | sed -e s/\'/./g)', '${PLAYER_POSITION}', '${PLAYER_OVE}', '${PLAYER_POT}', '${PLAYER_GRO}', '${PLAYER_AGE}', '${PLAYER_CONTRACT}', '${PLAYER_LIKE}', '${PLAYER_LINK}');" >> ${FILE_SQL} 
	done < ${TMP_OUTPUT}
done

echo -e "\ncommit;" >> ${FILE_SQL}

Exit_Script 0
