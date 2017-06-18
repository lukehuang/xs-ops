#!/bin/bash

set -eu
set -xv

source host.conf

sed -i  -e  's/_HOSTNAME_/'"$(hostname -f)"'/'                      \
        -e  's/^hostname.*/hostname='"$(hostname -f)"'/'            \
        -e  's/_DOMAINNAME_/'"$(hostname -f)"'/'                    \
        -e  's/^rewriteDomain.*/rewriteDomain='"$(hostname -f)"'/'  \
        -e  's/_MAILHUB_/'"$smtp_mailhub"'/'                        \
        -e  's/^mailhub.*/mailhub='"$smtp_mailhub"'/'               \
        -e  's/.*FromLineOverride.*/FromLineOverride=YES/'          \
  /etc/ssmtp/ssmtp.conf

temp_file=$(mktemp)
wget $(sed 's/\ /\n/g' /var/log/installer/cmdline-log | awk -F'=' '/answerfile=/{print $2}') -O "$temp_file"
root_password=$(xmllint "$temp_file" | awk -F"[><]" '/root-password/{print $3}')
rm "$temp_file"

( cat << EOF
TO        : $email_recepient
FROM      : root@"$(hostname -f)"
Subject   : Stage 1 setup of $(hostname -f) is now complete
CC        : admin@autostack.local
Reply-to  : #admin@autostack.local

The setup of $(hostname -f) is now complete. A bootstrap log file is 
attached to this email.

The following is a table of information to use in administering this host.

  * Hostname          : $(hostname -s)
  * FQDN              : $(hostname -f)
  * Owner             : $email_recepient
  * Platform version  : $(xe host-list uuid=$INSTALLATION_UUID params=software-version --minimal | sed -e 's/; /\n/g' -e 's@\\@@g' | awk -F': ' '/^xs:main/{print $2}')
  * Hotfixes          : $(xe host-list uuid=$INSTALLATION_UUID params=software-version --minimal | sed -e 's/; /\n/g' -e 's@\\@@g' | awk -F': ' '/Hotfix/{print $2}' )
  * Mgmt IP Address   : $(xe pif-list management=true params=IP --minimal)
  * UserName          : root
  * Password          : $root_password
  * XenCenter Host    : $(hostname -f)
  * XAPI URL          : http://$(hostname -f)/
  * AutoStack URL     : http://autostack.local/pxe/hosts/$(hostname -s)
  * Host UUID         : $INSTALLATION_UUID
  * Host ID           : $(hostid)
  * Install date      : $INSTALLATION_DATE

EOF

  echo "Running VMs"
  xe vm-list params=all is-control-domain=false |
    xe_grep 'printf " * %s   %s\n", name_label,networks'
  echo ""

  for file in "${stage1_log_files[@]}"; do
    uuencode "$file" "${file##*/}"
  done

) | sendmail -s "$email_recepient" 

