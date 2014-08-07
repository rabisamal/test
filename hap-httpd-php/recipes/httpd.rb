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
cookbook_file "#{document_root}/index.php" do
  source 'index.php'
  mode '0644'
end
