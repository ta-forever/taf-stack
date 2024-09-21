#!/bin/bash

mountpoint=~/taf-stack/data/content/objstore

for bn in replays-000 replays-001; do
    sudo umount ${mountpoint}/${bn}
    sudo s3fs ${bn} ${mountpoint}/${bn} -o passwd_file=~/taf-stack/.taf_data.objstore.passwd -o url=https://sjc1.vultrobjects.com -o allow_other
done
