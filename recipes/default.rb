# set up the database
include_recipe "mysql::client"
include_recipe 'user'
include_recipe 'myusa::ec2_vars'

app_id = 'myusa'

deploy_to_dir = "/var/www/#{app_id}"

# set up user and group
group node['myusa']['user']['group']

user_account node['myusa']['user']['username'] do
  gid node['myusa']['user']['group']
  action :create
end

include_recipe 'myusa::deploy'
include_recipe 'myusa::nginx'
