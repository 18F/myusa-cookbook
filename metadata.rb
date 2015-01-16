name             "myusa"
maintainer       "Diego Lapiduz"
maintainer_email "diego.lapiduz@gsa.gov"
description      "MyUSA app Installation and Setup"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends 'mysql'
depends 'database'

depends 'nodejs'
depends 'rbenv'
depends 'ruby_build'
depends 'unicorn'
depends 'nginx'
depends 'nginx_conf'

depends 'user'

depends 'citadel'
depends 'shipper', '~> 0.2.0'
