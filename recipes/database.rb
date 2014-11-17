# Set up mysql with root password

include_recipe 'mysql::server'

# Set up databases and users

include_recipe 'mysql::client'
include_recipe 'database::mysql'

mysql_connection_info = {
  host: node['myusa']['database']['host'],
  username: node['myusa']['database']['base_user'],
  password: node['mysql']['server_root_password']
}

mysql_database node['myusa']['database']['name'] do
  connection mysql_connection_info
  action :create
end

mysql_database_user node['myusa']['database']['username'] do
  connection mysql_connection_info
  password node['myusa']['database']['password']
  database_name node['myusa']['database']['name']
  privileges ['all']
  host 'localhost'
  action :grant
end
