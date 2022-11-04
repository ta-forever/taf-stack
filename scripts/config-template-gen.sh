#!/usr/bin/env bash

get_keys() {
    db_password=$(cat config/faf-db/faf-db.env | grep MYSQL_ROOT_PASSWORD | cut -d\= -f2)
    postal_password=$(cat config/faf-java-api/faf-java-api.env | grep MAIL_PASSWORD | cut -d\= -f2)
    mautic_client_secret=$(cat config/faf-java-api/faf-java-api.env | grep MAUTIC_CLIENT_SECRET | cut -d\= -f2)
    geo_ip_licence_key=$(cat config/faf-python-server/dynamic/config.yml | grep GEO_IP_LICENSE_KEY | cut -d\" -f2)
    turn_secret=$(cat config/faf-coturn/faf-coturn.env | grep TURN_SECRET | cut -d\= -f2)
    oauth_client_secret=$(cat config/faf-website/faf-website.env | grep OAUTH_CLIENT_SECRET | cut -d\= -f2)
    irc_opers_user_password=$(cat config/faf-ircd/unrealircd.conf | grep -P 'class[[:space:]]+opers;' -A 2 | grep -P 'password[[:space:]]+"[^"]+";' | cut -d\" -f2)
    irc_services_password=$(cat config/faf-ircd/unrealircd.conf | grep -P 'class[[:space:]]+servers;' -B 2 | grep -P 'password[[:space:]]+"[^"]+";' | cut -d\" -f2)
    readarray -t irc_cloak_keys < <(cat config/faf-ircd/unrealircd.conf | grep cloak-keys -A 5 | grep -P '[[:space:]]+"[^"]+";' | cut -d\" -f2)
    dashboard_htpasswd=$(cat .env | grep TRAEFIK_PASSWORD | cut -d\' -f2)
}

echo_keys() {
    echo db_password=\"${db_password}\"
    echo postal_password=\"${postal_password}\"
    echo mautic_client_secret=\"${mautic_client_secret}\"
    echo geo_ip_licence_key=\"${geo_ip_licence_key}\"
    echo turn_secret=\"${turn_secret}\"
    echo oauth_client_secret=\"${oauth_client_secret}\"
    echo irc_opers_user_password=\"${irc_opers_user_password}\"
    echo irc_services_password=\"${irc_services_password}\"
    for key in "${irc_cloak_keys[@]}"; do
        echo irc_cloak_key=\"${key}\"
    done
    echo dashboard_htpasswd=\"${dashboard_htpasswd}\"
}

get_keys config
#echo_keys

rm -fr config.template
cp -r config config.template
cp .env .env.template

scrub_file () {
    sed_args=" -e s/${db_password}/{{db_password}}/g"
    sed_args="${sed_args} -e s/${postal_password}/{{password_from_postal_web_configuration}}/g"
    sed_args="${sed_args} -e s/${mautic_client_secret}/{{mautic_client_secret}}/g"
    sed_args="${sed_args} -e s/${geo_ip_licence_key}/{{mindmax_dot_com_licence_key}}/g"
    sed_args="${sed_args} -e s/${turn_secret}/{{turn_secret}}/g"
    sed_args="${sed_args} -e s/${oauth_client_secret}/{{oauth_client_secret}}/g"
    sed_args="${sed_args} -e s/${irc_opers_user_password}/{{irc_opers_user_password}}/g"
    sed_args="${sed_args} -e s/${irc_services_password}/{{irc_services_password}}/g"
    for index in "${!irc_cloak_keys[@]}"; do
        sed_args="${sed_args} -e s/${irc_cloak_keys[$index]}/{{irc_cloak_key_$index}}/g"
    done
    sed_args="${sed_args} -e s/${dashboard_htpasswd}/{{dashboard_htpasswd}}/g"

    sed -i ${sed_args} "$1"
}

#x="sed -e s/'${dashboard_htpasswd}'/{{dashboard_htpasswd}}/g"
#echo ${x}
#exit

for fn in .env.template $(find config.template/ -type f | fgrep -v 'faf-postal/config/'); do
    scrub_file ${fn}
done
