#!/bin/bash

text_primary() { echo -n " $1 $(printf '\055%.0s' {1..70})" | head -c 70; echo -n ' '; }
text_success() { printf "\e[00;92m%s\e[00m\n" "$1"; }
text_danger() { printf "\e[00;91m%s\e[00m\n" "$1"; exit 0; }

USER_AGENT="Mozilla/5.0+(compatible; IP2Proxy/PostgereSQL-Docker; https://hub.docker.com/r/ip2proxy/postgresql)"
CODES=("PX1-LITE PX2-LITE PX3-LITE PX4-LITE PX5-LITE PX6-LITE PX7-LITE PX8-LITE PX9-LITE PX10-LITE PX11-LITE PX1 PX2 PX3 PX4 PX5 PX6 PX7 PX8 PX9 PX10 PX11 PX12")

if [ -f /ip2proxy.conf ]; then
	service postgresql start >/dev/null 2>&1
	tail -f /dev/null
fi

if [ "$TOKEN" == "FALSE" ]; then
	text_danger "Missing download token."
fi

if [ "$CODE" == "FALSE" ]; then
	text_danger "Missing database code."
fi

if [ "$POSTGRESQL_PASSWORD" == "FALSE" ]; then
	POSTGRESQL_PASSWORD="$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-12})"
fi

FOUND=""
for i in "${CODES[@]}"; do
	if [ "$i" == "$CODE" ] ; then
		FOUND="$CODE"
	fi
done

if [ -z $FOUND == "" ]; then
	text_danger "Download code is invalid."
fi

CODE=$(echo $CODE | sed 's/-//')

text_primary " > Create directory /_tmp "

mkdir /_tmp

[ ! -d /_tmp ] && text_danger "[ERROR]" || text_success "[OK]"

cd /_tmp

text_primary " > Download IP2Proxy database "

if [ "$IP_TYPE" == "IPV6" ]; then
	wget -O ipv6.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSVIPV6" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv6.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv6.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv6.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
else
	wget -O ipv4.zip -q --user-agent="$USER_AGENT" "https://www.ip2location.com/download?token=${TOKEN}&code=${CODE}CSV" > /dev/null 2>&1

	[ ! -z "$(grep 'NO PERMISSION' ipv4.zip)" ] && text_danger "[DENIED]"
	[ ! -z "$(grep '5 TIMES' ipv4.zip)" ] && text_danger "[QUOTA EXCEEDED]"

	RESULT=$(unzip -t ipv4.zip >/dev/null 2>&1)

	[ $? -ne 0 ] && text_danger "[FILE CORRUPTED]"
fi

text_success "[OK]"

for ZIP in $(ls | grep '.zip'); do
	CSV=$(unzip -l $ZIP | grep -Eo 'IP2PROXY-IP(V6)?.*CSV')

	text_primary " > Decompress $CSV from $ZIP "

	unzip -jq $ZIP $CSV

	if [ ! -f $CSV ]; then
		text_danger "[ERROR]"
	fi

	text_success "[OK]"
done

service postgresql start >/dev/null

text_primary " > [PostgreSQL] Create database \"ip2proxy_database\" "

RESPONSE="$(sudo -u postgres createdb ip2proxy_database 2>&1)"

[ ! -z "$(echo $RESPONSE | grep 'FATAL')" ] && text_danger "[ERROR]" || text_success "[OK]"

text_primary " > [PostgreSQL] Create table \"ip2proxy_database_tmp\" "

case "$CODE" in
	PX1|PX1LITE )
		FIELDS=', country_code char(2) NOT NULL, country_name varchar(64) NOT NULL'
	;;

	PX2|PX2LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL'
	;;

	PX3|PX3LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL'
	;;

	PX4|PX4LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL'
	;;

	PX5|PX5LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL'
	;;

	PX6|PX6LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL'
	;;

	PX7|PX7LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL'
	;;

	PX8|PX8LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL, last_seen integer NOT NULL'
	;;

	PX9|PX9LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL, last_seen integer NOT NULL, threat varchar(128)'
	;;

	PX10|PX10LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL, last_seen integer NOT NULL, threat varchar(128)'
	;;

	PX11|PX11LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL, last_seen integer NOT NULL, threat varchar(128), provider varchar(256) NOT NULL'
	;;
	
	PX12|PX12LITE )
		FIELDS=', proxy_type varchar(3) NOT NULL, country_code char(2) NOT NULL, country_name varchar(64) NOT NULL, region_name varchar(128) NOT NULL, city_name varchar(128) NOT NULL, isp varchar(255) NOT NULL, domain varchar(128) NOT NULL, usage_type varchar(11) NOT NULL, asn varchar(6) NOT NULL, "as" varchar(256) NOT NULL, last_seen integer NOT NULL, threat varchar(128), provider varchar(256) NOT NULL, fraud_score integer NOT NULL'
	;;
esac

RESPONSE="$(sudo -u postgres psql -c 'CREATE TABLE ip2proxy_database_tmp (ip_from decimal(39,0) NOT NULL, ip_to decimal(39,0) NOT NULL '"$FIELDS"', CONSTRAINT idx_key PRIMARY KEY (ip_from, ip_to));' ip2proxy_database 2>&1)"

[ -z "$(echo $RESPONSE | grep 'CREATE TABLE')" ] && text_danger "[ERROR]" || text_success "[OK]"

for CSV in $(ls | grep -i '.CSV'); do
	text_primary " > [PostgreSQL] Load $CSV into database "
	RESPONSE=$(sudo -u postgres psql -c 'COPY ip2proxy_database_tmp FROM '\''/_tmp/'$CSV''\'' WITH CSV QUOTE AS '\''"'\'';' ip2proxy_database 2>&1)

	[ -z "$(echo $RESPONSE | grep 'COPY')" ] && text_danger "[ERROR]" || text_success "[OK]"
done

text_primary " > [PostgreSQL] Rename table \"ip2proxy_database_tmp\" to \"ip2proxy_database\" "

RESPONSE="$(sudo -u postgres psql -c 'ALTER TABLE ip2proxy_database_tmp RENAME TO ip2proxy_database;' ip2proxy_database 2>&1)"

[ ! -z "$(echo $RESPONSE | grep 'ERROR')" ] &&  text_danger "[ERROR]" || text_success "[OK]"

sudo -u postgres psql -d ip2proxy_database -c "CREATE FUNCTION ip2int(inet) RETURNS bigint AS \$\$ SELECT \$1 - '0.0.0.0'::inet \$\$ LANGUAGE SQL strict immutable;GRANT execute ON FUNCTION ip2int(inet) TO public;" > /dev/null
sudo -u postgres psql -d postgres -c "ALTER USER postgres WITH PASSWORD '$POSTGRESQL_PASSWORD';" > /dev/null

echo "  > Setup completed"
echo ""
echo "  > You can now connect to this PostgreSQL Server using:"
echo ""
echo "   psql -h HOST -p PORT --username=postgres"
echo "   Password: $POSTGRESQL_PASSWORD"
echo ""

rm -rf /_tmp

echo "POSTGRESQL_PASSWORD=$POSTGRESQL_PASSWORD" > /ip2proxy.conf
echo "TOKEN=$TOKEN" >> /ip2proxy.conf
echo "CODE=$CODE" >> /ip2proxy.conf
echo "IP_TYPE=$IP_TYPE" >> /ip2proxy.conf

cd /

service postgresql start >/dev/null 2>&1

tail -f /dev/null