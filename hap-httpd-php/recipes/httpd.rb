document_root = '/var/www/html'
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
cookbook_file "#{document_root}/file.php" do
  source 'file.php'
  mode '0644'
end
#include_recipe "php"
