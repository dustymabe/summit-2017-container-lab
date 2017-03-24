#!/bin/bash

# This script will update all of the custom.repo yum repo files that
# are scattered throughout the repository. We could have used a
# symlink to a single file but building in Docker caused problems with
# that approach.

repofile=$(cat <<EOF
[rhel-7-server-rpms]
metadata_expire = 86400
baseurl = http://10.19.115.172/pub/rhel-7-server-rpms
name = rhel-7-server-rpms
enabled = 1
gpgcheck = 0

[rhel-7-server-optional-rpms]
metadata_expire = 86400
baseurl = http://10.19.115.172/pub/rhel-7-server-optional-rpms
name = rhel-7-server-optional-rpms
enabled = 1
gpgcheck = 0

[rhel-7-server-extras-rpms]
metadata_expire = 86400
baseurl = http://10.19.115.172/pub/rhel-7-server-extras-rpms
name = rhel-7-server-extras-rpms
enabled = 1
gpgcheck = 0
EOF
)

files=(
./vagrantcdk/custom.repo
./labs/lab1/custom.repo
./labs/lab1/registry/custom.repo
./labs/lab2/bigapp/custom.repo
./labs/lab3/mariadb/custom.repo
./labs/lab3/wordpress/custom.repo
)

for file in ${files[@]}; do
    echo "Writing to $file"
    echo "$repofile" > $file
done
