name 'elk'
maintainer 'KongZ'
maintainer_email ''
license 'all_rights'
description 'Install ELK Stack'
long_description 'Installation cookbook for ELK stach'
version '0.1.0'

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Issues` link
# issues_url 'https://github.com/<insert_org_here>/elk/issues' if respond_to?(:issues_url)

# If you upload to Supermarket you should set this so your cookbook
# gets a `View Source` link
# source_url 'https://github.com/<insert_org_here>/elk' if respond_to?(:source_url)
#
depends 'java'
depends 'elasticsearch'
depends 'logstash'
