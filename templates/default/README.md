## Templates
1. ceph.conf.erb
This of course is the most important template. It sets up the ceph.conf on each node and adjusts the settings that are defined by node['ceph']['config']['<whatever>'] where <whatever> is the sub-section such as 'global', 'mon', 'osd', 'rgw', 'mds'. This allows the user to add values EXACTLY like they would see them in the ceph.conf within their wrapper, library or application like cookbook. Very flexible.

Note: If there are values already existing in the ceph.conf.erb template then specifying them in the outer cookbook will simply override the existing attributes which is ok. They will both be present but the last one wins and warning will appear in the logs for reference purposes only.
