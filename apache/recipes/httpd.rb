package "httpd" do
action :install
end
template "/var/www/html/index.html" do
  source "index.html.erb"
  owner "root"
  group "root"
  mode "644"
end
# Stop iptables service permanently
service "iptables" do
        action [:disable,:stop]
end
# start httpd service
service "httpd" do
    action [:enable,:restart]
end
