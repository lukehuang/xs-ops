#!/bin/bash

# SYNOPSIS
#   Install available updates for a XenServer host/pool

set -eu
shopt -s extglob nullglob

source /etc/xensource-inventory

period="$(date +%Y%m%d%H)"

updates_xml_url="http://updates.xensource.com/XenServer/updates.xml"
updates_xml_file="updates-$period.xml"

local_sr=$(xe sr-list type=ext host=$(hostname) params=uuid --minimal | sed -r 's/,/\n/g' | tail -n 1)
[[ -z $local_sr ]] && 
  local_sr=$(xe sr-list other-config:i18n-key=local-storage params=uuid --minimal | sed -r 's/,/\n/g' | tail -n 1)
[[ -z $local_sr ]] &&
  local_sr=$(xe sr-list allowed-operations:contains=VDI.create host=$(hostname) params=uuid --minimal | sed -r 's/,/\n/g' | tail -n 1)

patch_cache_dir="/var/run/sr-mount/$local_sr/patch_cache"
mkdir -p "$patch_cache_dir"
cd "$patch_cache_dir"

if [[ ! -e "$updates_xml_file" ]]; then
  wget -c "$updates_xml_url" -O "$updates_xml_file"
fi

patch_tab="patch-$period.tab"

pool_master_uuid=$(xe pool-list params=master --minimal)
pool_master_name=$(xe host-list uuid="$pool_master_uuid" params=name-label --minimal)

echo "Discovering updates for '$(hostname)' ($INSTALLATION_UUID)"
echo "  pool_master      : ($pool_master_uuid) $pool_master_name"
echo "  this_host        : ($INSTALLATION_UUID) $(hostname)"
echo "  product_version  : $PRODUCT_VERSION"
echo "  updates_xml_url  : $updates_xml_url"
echo "  updates_xml_file : $updates_xml_file"
echo "  update_period    : $period"
echo "  patch_cache_dir  : $patch_cache_dir"
echo "  patch_tab        : $patch_tab"

echo ''
echo "Available updates for '$(hostname)' ($INSTALLATION_UUID), XenServer $PRODUCT_VERSION"
echo ''

python -c '
import sys
from xml.dom.minidom import parse

updates_file    = sys.argv[1]
product_version = sys.argv[2]

doc = parse( updates_file )

vers = doc.getElementsByTagName("version")
version = filter( lambda tag: tag.getAttribute("value") == product_version, vers)[0]
released_patches = version.getElementsByTagName("patch")
released_patch_uuids = map(lambda tag: tag.getAttribute("uuid"), released_patches)

patch_data = doc.getElementsByTagName("patches")[0]
released_patch_data = filter(lambda tag: tag.getAttribute("uuid") in released_patch_uuids, patch_data.getElementsByTagName("patch"))

released_patch_names = map(lambda tag: tag.getAttribute("name-label"), released_patch_data)
released_patch_descs = map(lambda tag: tag.getAttribute("name-description"), released_patch_data)
released_patch_urls = map(lambda tag: tag.getAttribute("patch-url"), released_patch_data)

for i, val in enumerate( released_patch_uuids ):
  print "%s  %s  %s  %s" % (released_patch_uuids[i], released_patch_names[i], released_patch_urls[i], released_patch_descs[i])

' "$updates_xml_file" "$PRODUCT_VERSION" > "$patch_tab"

# If we have Service Packs - omit the non-SP updates
if grep -Eq "XS[0-9]+ESP[0-9]" "$patch_tab"; then
  sed -r '/XS[0-9]+ESP[0-9]+/!d' "$patch_tab" > "$patch_tab.tmp"
  mv "$patch_tab.tmp" "$patch_tab"
fi
cat "$patch_tab"

while read uuid name url desc; do

  patch_def=$(xe patch-list uuid="$uuid")
  if [[ -n $patch_def ]]; then
    echo "Patch '$name' ($uuid) already applied, skipping ..."
    continue
  else
    [[ -e $name.zip ]]      && continue
    [[ -e $name.xsupdate ]] && continue

    echo ''
    echo "Downloading patch '$name' ($uuid) from '$url' ..."
    echo ''
    wget -c "$url" -O "$name.zip"
  fi

done < "$patch_tab"

for i in *.zip; do
  if [[ -e $i ]]; then
    xsupdate="${i%.zip}.xsupdate"
    if unzip -d "$patch_cache_dir" -o "$i" "$xsupdate"; then
      rm -f "$i"
    fi
  fi
done

patches_applied=()
apply_guidances=()

echo ''
while read -r uuid hotfix url description; do

  xsupdate="$hotfix.xsupdate"
  echo -e "Installing patch '$xsupdate' ($description).."
  echo "  hotfix      : $hotfix"
  echo "  description : $description"
  echo "  url         : $url"
  echo "  uuid        : $uuid"

  echo ''

  name_label=$( xe patch-list uuid="$uuid" params=name-label --minimal )

  if [[ -n $name_label ]]; then
    echo "  Patch '$hotfix' already uploaded to pool, skipping upload .."
  else
    if [[ -e "$xsupdate.sha256" ]]; then
      echo -e "  Checking SHA256SUM of $xsupdate .."
      sha256sum -c "$xsupdate.sha256"
    fi

    echo -e "  Uploading $xsupdate to pool master ..."
    uuid=$(xe patch-upload file-name="$xsupdate" || true)
    if [[ ! $uuid ]]; then
      echo "  Patch update file '$xsupdate' could not be uploaded to pool." >&2
      continue
    fi
  fi

  echo -e "  Performing prechecks for $xsupdate ($uuid) ..."
  { xe patch-precheck uuid="$uuid" host-uuid="$INSTALLATION_UUID" || true; } | tr -d $'\n'

  echo -e "  Applying patch $xsupdate ($uuid) to pool ..."
  xe patch-pool-apply uuid="$uuid"

  patches_applied+=( "$uuid:$xsupdate" )
  apply_guidances+=( $(xe patch-list uuid="$uuid" params="after-apply-guidance" --minimal) )

  echo ''
done < "$patch_tab"

echo "Patches applied : ${patches_applied[@]-}"
echo "Apply guidances : ${apply_guidances[@]-}"

