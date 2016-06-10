
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
./custom.repo
./lab1/custom.repo
./lab1/registry/custom.repo
./lab2/bigapp/custom.repo
./lab3/mariadb/custom.repo
./lab3/wordpress/custom.repo
)

for file in ${files[@]}; do
    echo "Writing to $file"
    echo "$repofile" > $file
done
