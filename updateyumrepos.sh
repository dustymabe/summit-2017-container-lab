#!/bin/bash

# This script will update all of the custom.repo yum repo files that
# are scattered throughout the repository. We could have used a
# symlink to a single file but building in Docker caused problems with
# that approach.

repofile=$(cat <<EOF
[rhel-7-server-rpms]
baseurl = http://10.1.2.4:8000/rhel-7-server-rpms
#baseurl = http://registry.access.redhat.com:8000/rhel-7-server-rpms
sslverify = 0
name = RHEL 7.2 DVD RPMs
enabled = 1
gpgcheck = 0

[rhel-7-server-updates-rpms]
baseurl = http://10.1.2.4:8000/rhel-7-server-updates-rpms
#baseurl = http://registry.access.redhat.com:8000/rhel-7-server-updates-rpms
sslverify = 0
name = RHEL 7.2 Updated RPMs
enabled = 1
gpgcheck = 0

[rhel-7-server-extras-rpms]
baseurl = http://10.1.2.4:8000/rhel-7-server-extras-rpms
#baseurl = http://registry.access.redhat.com:8000/rhel-7-server-extras-rpms
sslverify = 0
name = A subset of RHEL 7.2 Server Extras
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
