package "httpd" do
action :install
end

# Stop iptables service permanently
service "iptables" do
        action [:disable,:stop]
end
# start httpd service
service "httpd" do
    action [:enable,:restart]
end
