package "haproxy" do
action :install
end

# start haproxy service
service "haproxy" do
    action [:enable,:restart]
end
