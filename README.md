# xs-ops

XenServer host provisioning scripts used in autostack.

This is a collection of scripts useful in the automated provisioning (first-boot)
of a XenServer (>= 6.0) pool member.

While tied to autostack, these can easily be run outside the environment on 
isolated hosts.

## Usage
On the autostack console

- Create a launch-config for the XS host
- Define the XS hosts parameters in launch-config's host.conf
- Optionally symbolically linke to $HOSTNAME.conf
- Optionally define your sequence of scripts to be run on the host
- Scripts can be added in as long as they are executable within the XenServer
  host's Dom0 (sh, bash, python, perl, etc). _NOTE_ : As you are running these
  within Dom0 - care must be taken not to tamper with the install and/or violate
  the Citrix EULA.

# License

- None
