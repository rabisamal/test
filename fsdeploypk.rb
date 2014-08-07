# Usage" fsdeploy.rb deploy railsapp staging railsapp1 true
$time= Time.now
puts "@@@@  Starting deploy at #{$time}"
# Chef requires
require "chef"
require 'chef/knife'
require 'chef/knife/bootstrap'
require 'winrm'
require 'em-winrm'
require 'chef/knife/bootstrap_windows_winrm'
require "chef/knife/core/bootstrap_context"
require 'chef/knife/ssh'
require 'net/ssh'
require 'net/ssh/multi'
require 'base64'
require 'json'
require 'ostruct'
require 'active_support/time'
require 'getoptlong'


Chef::Config.from_file('/home/ubuntu/opscode-chef-repo/.chef/knife.rb')

 $production_ami_id = "ami-d13845e1"
 $node_private_key =  "pkfsdemokeypair.pem"
 $ssh_key =  "pkfsdemokeypair.pem"
 $ssh_user =  "ec2-user"
 $region =  "us-west-2"
 $availability_zone =  "us-west-2a"
 $web_nodes =  "2"
 $subnet="subnet-b97d95ce"
 $application_cookbook="apache"
 $elbname="fhdelb"

def exec_cmd(query,exit_on_failure=true)
     puts "run cmd : #{query}"
     output =''
      stdin, stdout, wait_thr = Open3.popen2e(query);
     while line = stdout.gets

           puts line

          output=output+line
  end
   exit_status = wait_thr.value
   unless exit_status.success?
        if exit_on_failure
        abort "FAILED !!! #{query} \n Error: #{output}"
   end
   end
  output
end
############## CREATING INSTANCES ####################################
$query = "knife ec2 server create --flavor t2.micro --identity-file fsdemokeypair.pem --image ami-d13845e1 --security-group-ids sg-856dd6e0 --subnet subnet-74e12b11 --ssh-user ec2-user --region us-west-2 --ssh-port 22  --node-name fsdemo_haproxy"
exec_cmd($query)

$query = "knife ec2 server create --flavor t2.micro --identity-file fsdemokeypair.pem --image ami-d13845e1 --security-group-ids sg-856dd6e0 --subnet subnet-74e12b11 --ssh-user ec2-user --run-list 'recipe[apache::httpd]' --region us-west-2 --ssh-port 22  --node-name fsdemo_web_01"
exec_cmd($query)

$query = "knife ec2 server create --flavor t2.micro --identity-file fsdemokeypair.pem --image ami-d13845e1 --security-group-ids sg-856dd6e0 --subnet subnet-74e12b11 --ssh-user ec2-user --run-list 'recipe[apache::httpd]' --region us-west-2 --ssh-port 22  --node-name fsdemo_web_02"
exec_cmd($query)
############# SAVING PRIVATE IPS ######################################

$query=%Q{knife node show fsdemo_haproxy -l --format=json -a ipaddress| grep "ipaddress" | awk 'BEGIN {FS="\\""} {print $4}'}
$haproxy_private_ip=exec_cmd($query)
@haproxy_private_ip = "#{$haproxy_private_ip}"
@haproxy_private_ip.delete!("\n")
$query=%Q{knife node show fsdemo_web_01 -l --format=json -a ipaddress| grep "ipaddress" | awk 'BEGIN {FS="\\""} {print $4}'}
$web_private_ip_01=exec_cmd($query)
@web_private_ip_01 = "#{$web_private_ip_01}"
@web_private_ip_01.delete!("\n")
$query=%Q{knife node show fsdemo_web_02 -l --format=json -a ipaddress| grep "ipaddress" | awk 'BEGIN {FS="\\""} {print $4}'}
$web_private_ip_02=exec_cmd($query)
@web_private_ip_02 = "#{$web_private_ip_02}"
@web_private_ip_02.delete!("\n")

########### SETTING NODE ATTRIBUTES ##################################
$query=%Q{knife exec -E "nodes.find(:name => 'fsdemo_haproxy') { |node| node.normal_attrs[:"web_private_ip_01"] = '#{@web_private_ip_01}'; node.save; }"}
exec_cmd($query)
$query=%Q{knife exec -E "nodes.find(:name => 'fsdemo_haproxy') { |node| node.normal_attrs[:"web_private_ip_02"] = '#{@web_private_ip_02}'; node.save; }"}
exec_cmd($query)
$query=%Q{knife exec -E "nodes.find(:name => 'fsdemo_haproxy') { |node| node.normal_attrs[:"haproxy_private_ip"] = '#{@haproxy_private_ip}'; node.save; }"}
exec_cmd($query)
######## APPLYING HAPROXY SETTINGS #########################################

$query = "knife ssh name:fsdemo_haproxy -x ec2-user --identity-file fsdemokeypair.pem " +
                            " \"sudo chef-client  --user root --log_level info -o recipe[apache::haproxy] \""
exec_cmd($query)
####################CREATING LOAD BALANCER ABD ADDING NODES TO IT ###########################
$query=%Q{knife node show fsdemo_web_01 -l --format=json -a ec2.instance_id| grep "instance_id" | awk '{split($0,a,"\\""); print a[4]}'}
$web01_instance_id = exec_cmd($query)

$query=%Q{knife node show fsdemo_web_02 -l --format=json -a ec2.instance_id| grep "instance_id" | awk '{split($0,a,"\\""); print a[4]}'}
$web02_instance_id = exec_cmd($query)

$query=%Q{aws elb create-load-balancer --load-balancer-name #{$elbname} --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets subnet-d7a3ab91 subnet-b97d95ce subnet-74e12b11  --security-groups sg-856dd6e0}
exec_cmd($query)

$query=%Q{aws elb modify-load-balancer-attributes --load-balancer-name #{$elbname} --load-balancer-attributes '{  "CrossZoneLoadBalancing": {  "Enabled": true } }'}
exec_cmd($query)

$query=%Q{aws elb register-instances-with-load-balancer --load-balancer-name #{$elbname} --instances #{$web01_instance_id}}
exec_cmd($query)

$query=%Q{aws elb register-instances-with-load-balancer --load-balancer-name #{$elbname} --instances #{$web02_instance_id}}
exec_cmd($query)

$final_time = Time.now
puts "@@@@@@@@@@@@@@@ Finished Deploying  #{$time} @@@@@@@@@@@@@@@@@@"
