package "php" do
action :install
end
package "php-gd" do
action :install
end
package "php-pdo" do
action :install
end
package "php-pear" do
action :install
end
package "php-xml" do
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

