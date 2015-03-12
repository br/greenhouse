require 'aws-sdk'

BASE_AMI = "ami-a66723ce"
DOCKER_SOLUTION_STACK = "64bit Amazon Linux 2014.09 v1.0.11 running Docker 1.3.3"
DOCKERHUB_EMAIL = "felix.a.rod@gmail.com"
DOCKERHUB_USER = "feelobot"
DOCKERHUB_PASS = 

script2 =  '#!/bin/bash' +
          'docker login -e #{DOCKERHUB_EMAIL} -u #{DOCKERHUB_USER} -p #{DOCKERHUB_PASS}' + 
          'docker pull bleacher/#{repo}/:#{latest_tag}'

Aws.config[:credentials]


repo = "cms"
latest_tag = "br-master-cc680b3"

script = %Q(
#cloud-config
repo_update: true
repo_upgrade: all
output : { all : '| tee -a /var/log/cloud-init-output.log' }

runcmd:
 - docker login -e #{DOCKERHUB_EMAIL} -u #{DOCKERHUB_USER} -p #{DOCKERHUB_PASS}'
 - docker pull bleacher/#{repo}/:#{latest_tag}
)

ec2 = Aws::EC2::Resource.new
instances = ec2.create_instances(
  :max_count => 1,
  :min_count => 1,
  :key_name => "feelobot",
  :instance_type => "m3.medium",
  :dry_run => false,
  :image_id => BASE_AMI,
  :user_data => Base64.encode64(script)
)

puts ec2.inspect
### PULL FROM QUAY ALSO
#docker login -e #{QUAY_EMAIL} -u #{QUAY_USER} -p #{QUAY_PASS}
#docker pull quay.io/bleacherreport/#{repo}
##### TEMPLATE FOR CREATING A NEW AMI IMAGE
=begin
resp = ec2.create_image(
  dry_run: true,
  # required
  instance_id: "String",
  # required
  name: "String",
  description: "String",
  no_reboot: true,
  block_device_mappings: [
    {
      virtual_name: "String",
      device_name: "String",
      ebs: {
        snapshot_id: "String",
        volume_size: 1,
        delete_on_termination: true,
        volume_type: "standard|io1|gp2",
        iops: 1,
        encrypted: true,
      },
      no_device: "String",
    },
  ],
)
=end