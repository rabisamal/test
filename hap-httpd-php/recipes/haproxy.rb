package "haproxy" do
action :install
end

# Stop iptables service permanently
service "iptables" do
        action [:disable,:stop]
end
# start httpd service
service "haproxy" do
    action [:enable,:restart]
end

