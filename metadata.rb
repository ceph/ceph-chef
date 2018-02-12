name 'ceph-chef'
maintainer 'Hans Chris Jones'
maintainer_email 'chris.jones@lambdastack.io'
license 'Apache v2.0'
description 'Installs/Configures Ceph (Jewel and above)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.1.28'

depends	'apache2', '>= 1.1.12'
depends 'apt'
depends 'yum', '>= 3.8.1'
depends 'yum-epel'
depends 'poise', '>= 2.5.0'
depends 'chef-sugar', '>= 3.3.0'

supports 'ubuntu', '>= 14.04'
supports 'redhat', '>= 7.1'
supports 'centos', '>= 7.1'

issues_url 'https://github.com/ceph/ceph-chef/issues'
source_url 'https://github.com/ceph/ceph-chef'
