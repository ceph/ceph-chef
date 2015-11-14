name 'ceph-chef'
maintainer 'Chris Jones'
maintainer_email 'cjones303@bloomberg.net'
license 'Apache 2.0'
description 'Installs/Configures Ceph (Hammer and above)'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.0'

depends	'apache2', '>= 1.1.12'
depends 'apt'
depends 'yum', '>= 3.8.1'
depends 'yum-epel'
