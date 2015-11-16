## providers
1. ceph_chef_pool.rb
This provider is very import to the cookbook. It allows for easy creation, setting and deleting of pools. It allows for setting replica size and types such as replica or erasure coding.

2. client.rb
This provider allows for simple creation of basic ceph clients such as radosgw. Currently it's not in use but may be updated soon to replace blocks found in the radosgw.rb recipe.

3. cephfs.rb
Specific only to cephfs.
