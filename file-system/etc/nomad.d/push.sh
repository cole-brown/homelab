#!/usr/bin/env bash

# -o pipefail = set exit code of a sequence of piped commands to an error if any of them errored
# -e          = exit on first error
set -eo pipefail

_script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

git_root="$(git rev-parse --show-toplevel)"

ssh_host="raspi"

path_src="${git_root}/file-system/etc/nomad.d"
path_dest_home="push/etc/nomad.d"
path_dest_etc="/etc/nomad.d"

# ------------------------------------------------------------------------------
# Script
# ------------------------------------------------------------------------------

# Backup current?
# No... KISS to start with.
set -x
# Push new files to path we can write to...
rsync -av --mkpath --delete \
      "${path_src}/" \
      "${ssh_host}:${path_dest_home}/"

# Change ownership/perms to be correct.
ssh raspi -t "sudo chown nomad:nomad ${path_dest_home}/*; sudo chmod 755 ${path_dest_home}/*"

# Move into correct place.
ssh raspi -t "sudo mv ${path_dest_home}/* ${path_dest_etc}/"

# Tell Nomad about it.
ssh raspi -t "sudo systemctl reload nomad"
