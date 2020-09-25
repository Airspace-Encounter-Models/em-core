#!/bin/sh
# Copyright 2018 - 2020, MIT Lincoln Laboratory
# SPDX-License-Identifier: BSD-2-Clause

# script/bootstrap:
# Resolve all dependencies that the application requires to run.
# This can mean packages, software language versions, Git submodules, etc.
# The goal is to make sure all required dependencies are installed.

# Install based on OS
# https://stackoverflow.com/a/3466183/363829
case "$(uname -s)" in
   Darwin)
      # Do something under Mac OS X platform
    echo "Kernal = Mac OS X, nothing to do"
     ;;

   Linux)
       # Do something under GNU/Linux platform
    echo "Kernal = Linux, using apt install"
    # xpath for xml parsing
    apt install libxml-xpath-perl
    # unzip to extract zip archives
    apt install unzip
     ;;
esac

# git submodules
# https://git-scm.com/book/en/v2/Git-Tools-Submodules

# initialize, fetch and checkout any nested submodules
git submodule update --init --recursive

## Check for $AEM_DIR_CORE
# https://stackoverflow.com/q/3601515
if [ -z "${AEM_DIR_CORE:-}" ]; then echo "AEM_DIR_CORE is unset"; else echo "AEM_DIR_CORE is set to '$AEM_DIR_CORE'"; fi
#echo "AEM_DIR_CORE is set to '$AEM_DIR_CORE'"
