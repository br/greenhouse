require 'pp'
require 'aws-sdk'
require 'sinatra'
require 'newrelic_rpm'
require 'json'

Aws.config[:credentials]

set(:method) do |method|
  method = method.to_s.upcase
  condition { request.request_method == method }
end

before :method => :post do
  error 401 unless params['token'] == ENV['TOKEN']
end

get '/up/elb' do
  "OK"
end

post '/create/instances' do
  content_type :json
  result = {}
  repos_string = params['repos']
  repos = repos_string.split(",")
  base_ami = params['base_ami']
  repos.each do | repo |
    tag = get_latest_tag(repo)
    ami_instance = create_instance(repo, tag, base_ami)
    result.merge!(repo.to_sym => ami_instance)
  end
 result.to_json
end

post '/create/ami' do
  create_ami(params)
  200
end

post '/cleanup/instances' do
  ec2 = Aws::EC2::Client.new
  instances = get_stale_build_instances
  if instances.any?
    ec2.terminate_instances(
      dry_run: false,
      instance_ids: instances 
    )
    "{ 'terminated': #{instances} }"
  else
    200
  end
end

post '/cleanup/images' do
  @ec2 = Aws::EC2::Client.new
  amis = get_greenhouse_amis
  delete_stale_amis amis 
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
  ec2 = Aws::EC2::Client.new
  instance_id = params[:instance_id]
  tag = params[:tag]
  repo = params[:repo]
  time = Time.now.strftime("%m-%d-%Y-%I-%M%p")
  resp = ec2.create_image(
    dry_run: dry?,
    # required
    instance_id: instance_id,
    # required
    name: "greenhouse-#{repo}-#{tag}-ami-#{time}",
    description: "Baked AMI",
    no_reboot: true,
  )
  puts resp
end

def script repo,tag
<<-eos
#!/bin/bash
echo "whoami in pwd" >/tmp/echolog
docker login -e #{ENV['DOCKER_EMAIL']} -u #{ENV['DOCKER_USER']} -p #{ENV['DOCKER_PASS']} &> /tmp/dockerlog
docker pull #{ENV['DOCKER_ACCOUNT']}/#{repo}:#{tag}  &> /tmp/dockerlog
#docker login -e #{ENV['QUAY_EMAIL']} -u #{ENV['QUAY_USER']} -p #{ENV['QUAY_PASS']}
#docker pull quay.io/bleacherreport/#{repo}
### START CREATING AMI
export EC2_INSTANCE_ID=$(cat /var/lib/cloud/data/instance-id)
curl -X POST -F instance_id=$EC2_INSTANCE_ID -F tag=#{tag} -F repo=#{repo} -F token=#{ENV['TOKEN']} #{ENV['GREENHOUSE_URL']}/create/ami &> /tmp/ami-log
eos
end

def get_latest_tag repo
  eb = Aws::ElasticBeanstalk::Client.new
  resp = eb.describe_application_versions(
    application_name: repo,
  )
  label = resp["application_versions"].select {|version| version["version_label"].include?("br-master") }.last
  if label
    label["version_label"].split("-")[0..2].join('-')
  else
    raise "No Master Tags Deployed:\n #{resp["application_versions"].inspect}"
    500
  end
end

def dry?
  ENV['DRY'] ? true : false
end

def get_stale_build_instances 
  params["tag_key"] ||= "Build Role"
  ec2 = Aws::EC2::Client.new
  stale_build_instances = ec2.describe_instances(
    dry_run: dry?,
    filters: [
      {
        name: "tag-key",
        values: [params["tag_key"]],
      },
      {
        name: "instance-state-code",
        values: ["16"]
      }
    ]
  )
  instances = stale_build_instances[:reservations].map(&:instances)
  stale_instances = []
  params[:time] ||= "1"
  instances.each do |instance|
    if time_diff(instance[0][:launch_time]) > params[:time].to_i
      stale_instances << instance[0][:instance_id]
    end
  end
  stale_instances
end

def time_diff launch_time
  ((Time.now.utc - launch_time) / 3600)
end

def get_greenhouse_amis
  amis = @ec2.describe_images(filters: [{ name: "description", values: ["Baked AMI"] }])[:images]
  amis.map(&:image_id)
end

def delete_stale_amis amis
  amis.each do |id|
    if ami_unattached_to_instance(id) && ami_stale(id)
      delete_ami(id)
    end
  end
end
    
def ami_unattached_to_instance id
  @ec2.describe_instances(filters: [{ name: "image-id", values: [ id ]}])[:reservations].empty?
end

def ami_stale id
  params[:time] ||= "6"
  date =  @ec2.describe_images(image_ids: [ id ])[:images].first[:creation_date]
  time_diff(Time.parse(date)) > params[:time].to_i ? true : false
end 

def delete_ami id
  puts "Deregestering #{id}"
  @ec2.deregister_image(
  dry_run: dry?,
  # required
  image_id: id,
)
end
