

repofile=$(cat <<EOF
#   [rhel-x86_64-server-7]
#   baseurl = http://content.example.com/packages/rhel-x86_64-server-7/
#   sslverify = 0
#   name = Server
#   enabled = 1
#   gpgcheck = 0

#   [rhel-x86_64-server-extras-7]
#   baseurl = http://content.example.com/packages/rhel-x86_64-server-extras-7/
#   sslverify = 0
#   name = Extras
#   enabled = 1
#   gpgcheck = 0

#   [rhel-x86_64-server-optional-7]
#   baseurl = http://content.example.com/packages/rhel-x86_64-server-optional-7/
#   sslverify = 0
#   name = Optional
#   enabled = 1
#   gpgcheck = 0
EOF
)

files=(
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
