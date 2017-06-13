#!/bin/bash
#
# Author:: Hans Chris Jones <chris.jones@lambdastack.io>
#
# Copyright 2017, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script takes 2 parameters: option and device
# It uses the ceph-disk script to make things easier. You can also use
# partx -s <device> to get a list of partitions without using ceph-disk
# NOTE: If you delete a journal partition (assuming journals are on device
# different than ceph data) then update the kernel with partprobe or partx
# so that ceph-disk does not pickup something that says something like
# 'other...' in journal partition descriptions.

# OUTPUT: The ceph-disk script may output a warning message. This will
# have no impact on the results of the script.

opt=$1
dev=$2

journal=$(ceph-disk list | grep $dev | awk -F',' '{print $5}' 2>/dev/null)

# returns the full journal output line from ceph-disk for the given device
if [[ $opt == 0 ]]; then
  echo $journal
fi

# NOTE: If you have not run partx or partprobe after removing a journal partition
# (again only if the journals are not on the same device as the data) then
# you may see output that looks like 'option' which will not format well.
# returns the full device/partition of the given device
if [[ $opt == 1 ]]; then
  echo $journal | sed 's/journal //g'
fi

# Different 'if' clauses for 'opt' options
# returns only the partition number. This is good for using in sgdisk or partx
# for removing a specific journal partition.
if [[ $opt == 2 ]]; then
  echo $journal | sed 's/[a-Z]*[//]*//g'
fi
