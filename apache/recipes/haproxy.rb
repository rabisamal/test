$server_private_ip_01=node.normal.web_private_ip_01
$server_private_ip_02=node.normal.web_private_ip_02
package "haproxy" do
  action :install
end
template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
  owner "root"
  group "root"
  mode "644"
variables(
        :web_server_01 => "#{$server_private_ip_01}",
        :web_server_02 => "#{$server_private_ip_02}"
)
end
service "haproxy" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :restart]
end
