ceph-chef
=========

NOTE: You can find out how to use this cookbook and see how Bloomberg uses it at:
https://github.com/bloomberg/chef-bcs

v0.9.0 (2015-11-17)
-------------------

BETA: Documentation needs more clarity and substance. There are still true OS agnostic testing going on. One major
change coming is an update to the newer Chef style of moving provider/resource into classes in the libraries folder.
This will simplify the cookbook structure going forward.

- Support for Chef 12.5+
- Complete Ceph functionality
- Only supports Ceph Hammer and above
- RADOS Gateway (RGW) only supports civetweb style (no Apache)
