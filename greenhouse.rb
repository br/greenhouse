require 'aws-sdk'
require 'sinatra'
require 'json'

DOCKER_SOLUTION_STACK = "64bit Amazon Linux 2014.09 v1.0.11 running Docker 1.3.3"
Aws.config[:credentials]

post '/create/instances' do
  content_type :json
  result = {}
  data = JSON.parse(request.body.read) 
  repos = data["repos"]
  base_ami = data["base_ami"]
  repos.each do | repo |
    tag = get_latest_tag(repo)
    ami_instance = create_instance(repo, tag, base_ami)
    result.merge!(repo.to_sym => ami_instance)
  end
 result.to_json
end

post '/create/ami' do
 create_ami(params)
end

get '/up/elb' do
 "OK"
end

def create_instance repo, tag, base_ami
  ec2 = Aws::EC2::Resource.new
  instances = ec2.create_instances(
    :max_count => 1,
    :min_count => 1,
    :key_name => "feelobot",
    :instance_type => "m1.small",
    :dry_run => dry?,
    :image_id => base_ami, 
    :user_data => Base64.encode64(script(repo,tag))
  )
  instances.first.create_tags(
    :tags => [{
      key: "Build Role",
      value: "greenhouse_#{repo}",
   }]
  )
  instances.map(&:id).first
end

def create_ami params
  instance_id = params[:instance_id]
  tag = params[:tag]
  repo = params[:repo]
  resp = ec2.create_image(
    dry_run: dry?,
    # required
    instance_id: instance_id,
    # required
    name: "#{repo}-#{tag}-ami-#{Time.now}",
    description: "Baked AMI",
    no_reboot: true,
    block_device_mappings: [
      {
        virtual_name: "String",
        device_name: "String",
        ebs: {
          snapshot_id: "#{repo}-#{tag}-ebs-#{Time.now}",
          delete_on_termination: false,
        }
      }
    ]
  )
  puts resp
end

def script repo,tag
<<-eos
#!/bin/bash
echo "whoami in pwd" >/tmp/echolog
docker login -e #{ENV['DOCKER_EMAIL']} -u #{ENV['DOCKER_USER']} -p #{ENV['DOCKER_PASS']} &> /tmp/dockerlog
docker pull bleacher/#{repo}:#{tag}  &> /tmp/dockerlog
#docker login -e #{ENV['QUAY_EMAIL']} -u #{ENV['QUAY_USER']} -p #{ENV['QUAY_PASS']}
#docker pull quay.io/bleacherreport/#{repo}
### START CREATING AMI
export EC2_INSTANCE_ID=$(cat /var/lib/cloud/data/instance-id)
eos
end

def get_latest_tag repo
  "br-master-fb84878"
end

def dry?
  ENV['DRY'] ? true : false
end
