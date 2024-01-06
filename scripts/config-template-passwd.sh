#!/usr/bin/env bash

search=$1
replace=$2

usage () {
    echo "USAGE: $0 <source_key> <replace_key>"
    echo "eg: $0 db_password banana"
}

print_available_keys () {
    echo "Available keys:"
    grep -ore '{{.*}}' .env config/* | cut -d: -f2 | sort | uniq
}

if [ "$search" = "" ]; then
    usage
    print_available_keys
    exit
fi


shopt -s globstar

hit_count=0
replace_count=0
search="{{${search}}}"
for extension in env cnf conf yml; do
    before_count=$(grep -e "${search}" .env config/**/*.${extension} | wc -l)
    if [ "$replace" != "" ]; then
        sed -i -e s/${search}/${replace}/g .env config/**/*.${extension}
    fi
    after_count=$(grep -e "${search}" .env config/**/*.${extension} | wc -l)

    hit_count=$((hit_count + before_count))
    replace_count=$((replace_count + before_count - after_count))
done

echo "hit_count=${hit_count} occurences found"
echo "replace_count=${replace_count} replacements made"
