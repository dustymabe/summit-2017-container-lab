
Some files in here that aid in creation of lab environment VM.

- summitlab-atomic-from-iso.sh

script to run a kickstart install of an atomic host ISO and do some
configuration in %post

- summitlab-kickstart-from-iso.sh

script to create the labvm that houses the atomic vm and also has
minishift in it.

- summitlab-cmds-to-run-after-boot.sh

commands to run after the kickstart of the labvm and after it has
already booted. Thinks like setting up minishift which includes
downloading ose containers and setting up oc cluster which also
includes downloading ose containers.
