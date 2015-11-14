## ceph-radosgw
This file represents an updated init script that resides in /etc/init.d for RPM based environments. This is a work around that can be removed once the change has been fixed upstream in ceph-radosgw rpm. The comment and reference to the known issue is inline in the ceph-radosgw bash script.

## release.asc
This file is the new ceph repo key. This file only changes if there is a serious issue such as a breach in the repo. If the key has to be replaced then there should be a recipe that does that and updates any mirrored repos that may be impacted. This key is updated locally so as to not have to pull it each time. This is very important for those installs behind proxies etc.
