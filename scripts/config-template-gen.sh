#!/usr/bin/env bash

get_keys() {
    local root="$1"
    db_password=$(cat ${root}/faf-db/faf-db.env | grep MYSQL_ROOT_PASSWORD | cut -d\= -f2)
    user_password=$(cat ${root}/faf-anope/services.conf | grep 'password *= *' | fgrep -v ${db_password} | cut -d\" -f2)
    geo_ip_licence_key=$(cat ${root}/faf-python-server/dynamic/config.yml | grep GEO_IP_LICENSE_KEY | cut -d\" -f2)
    postal_password=$(cat ${root}/faf-java-api/faf-java-api.env | grep MAIL_PASSWORD | cut -d\= -f2)
    turn_secret=$(cat ${root}/faf-coturn/faf-coturn.env | grep TURN_SECRET | cut -d\= -f2)
    mautic_client_secret=$(cat ${root}/faf-java-api/faf-java-api.env | grep MAUTIC_CLIENT_SECRET | cut -d\= -f2)
    oauth_client_secret=$(cat ${root}/faf-website/faf-website.env | grep OAUTH_CLIENT_SECRET | cut -d\= -f2)
    readarray -t irc_clock_keys < <(cat ${root}/faf-ircd/unrealircd.conf | grep cloak-keys -A 5 | grep -P ' *"[0-9a-zA-Z]*";' | cut -d\" -f2)
}

echo_keys() {
    echo db_password=\"${db_password}\"
    echo user_password=\"${user_password}\"
    echo postal_password=\"${postal_password}\"
    echo geo_ip_licence_key=\"${geo_ip_licence_key}\"
    echo turn_secret=\"${turn_secret}\"
    echo mautic_client_secret=\"${mautic_client_secret}\"
    echo oauth_client_secret=\"${oauth_client_secret}\"

    for key in "${irc_clock_keys[@]}"; do
	echo irc_clock_key=\"${key}\"
    done
}

if [ "$1" = "" ]; then
    get_keys config
    echo_keys
else
    get_keys "$1"
    echo_keys
    exit
fi

rm -fr config.template
cp -r config config.template
cp .env .env.template

scrub_file () {
    sed_args="-e s/${db_password}/the_db_root_password/g"
    sed_args="${sed_args} -e s/${user_password}/a_user_password/g"
    sed_args="${sed_args} -e s/${postal_password}/password_from_postal_web_configuration/g"
    sed_args="${sed_args} -e s/${geo_ip_licence_key}/mindmax_dot_com_licence_key/g"
    sed_args="${sed_args} -e s/${turn_secret}/a_secret_key/g"
    sed_args="${sed_args} -e s/${mautic_client_secret}/mautic_client_secret/g"
    sed_args="${sed_args} -e s/${oauth_client_secret}/a_key_to_match_faf_oauth_db_table/g"
    
    for key in "${irc_clock_keys[@]}"; do
	sed_args="${sed_args} -e s/${key}/a_clock_key/g"
    done

    sed -i ${sed_args} "$1"
}

for fn in $(find config.template/ -type f | fgrep -v 'faf-postal/config/'); do
    scrub_file ${fn}
done
