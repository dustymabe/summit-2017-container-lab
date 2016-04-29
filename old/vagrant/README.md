
Environment
===========

### NOTE: this might be a little borked currently, concentrating on the libvirt version right now

To set up the entire environment from F21 install packages (along with deps):

```
yum install -y vagrant vagrant-libvirt ruby-devel gcc-g++ libvirt-devel
```

If libvirt was installed you may need to enable/start the service:

```
systemctl enable libvirtd.service
systemctl start libvirtd.service
```

If you're not using root and don't like typing your password then add
something like:

```
USERNAME=<yourusername>
cat <<EOF > /etc/polkit-1/localauthority/50-local.d/vagrant.pkla
Identity=unix-user:$USERNAME
Action=org.libvirt.unix.manage
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF
```

Install the plugins that we need:

```
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-registration
```

Download the boxes that we need:

```
vagrant box add --name rhel-server-7 http://x.x.redhat.com/~lawhite/rhel-server-libvirt-7.1-1.x86_64.box
vagrant box add --name rhel-atomic-7 http://x.x.redhat.com/~lawhite/rhel-atomic-libvirt-7.1-1.x86_64.box
```

OPTIONAL: Set your rhn user/pass

```
 export SUB_USERNAME='username'
 export SUB_PASSWORD='password'
```

Now you should be able to *vagrant up* and have it come up!
