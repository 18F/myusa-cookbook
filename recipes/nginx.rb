app_id = 'myusa'
deploy_to_dir = "/var/www/#{app_id}"

service 'nginx' do
  supports status: true, restart: true, reload: true
  action   :restart
end

nginx_folder = "/etc/nginx/vhosts"
nginx_folder = "/etc/nginx/conf.d" if !File.exist?(nginx_folder)

template "#{nginx_folder}/#{app_id}.conf" do
  source "nginx.conf.erb"
  notifies :restart, "service[nginx]"
  variables(
    working_dir: "#{deploy_to_dir}/current",
    app_id: app_id,
    cert_path: "/etc/ssl/server.crt",
    cert_key_path: "/etc/ssl/server.key"
  )
end

file "#{nginx_folder}/default.conf" do
  action :delete
end

# Add upstart script
template "/etc/init/myusa.conf" do
  source "myusa.upstart.erb"
  variables(
    app_host: node['myusa']['app_host'],
    sms_number: node['myusa'['sms_number'],
    smtp_host: node['myusa']['smtp_host'],
    smtp_port: node['myusa']['smtp_port'],
    elasticache_endpoint: node['myusa']['elasticache']['endpoint'],
    working_dir: "#{deploy_to_dir}/current",
    app_user: node['myusa']['user']['username'],
    rails_env: node['myusa']['rails_env']
  )
  owner  "root"
  group  "root"
  mode   "0644"
end

service "myusa" do
  provider Chef::Provider::Service::Upstart
  action   [:enable, :start]
end

file "/etc/ssl/server.key" do
  action :create
  owner  "root"
  group  "root"
  mode   "0644"
  content node['myusa']['ssl']['key']
end

file "/etc/ssl/server.crt" do
  action :create
  owner  "root"
  group  "root"
  mode   "0644"
  content node['myusa']['ssl']['cert']
end
