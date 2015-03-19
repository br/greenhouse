# Setup
Set the following environment variables:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

AWS_REGION

DOCKER_EMAIL

DOCKER_USER

DOCKER_PASS

DOCKER_ACCOUNT

TOKEN

RACK_ENV

#### Setup a Runscope Scheduler
![](http://bleacher-report.d.pr/19ZIv.png)

# Endpoints
#### Create build instances
```bash
curl -X POST -F repos=cms -F base_ami=ami-a66723ce -F token=YOUR_API_TOKEN http://localhost:9292/create/instances
```
#### Clean up old instances
```bash
curl -X POST -F repos=cms -F tag_key='Build Role' -F time=3600 token=YOUR_API_TOKEN http://localhost:9292/cleanup/instances
```

#### Create AMIS
```bash
curl -X POST -F instance_id=i-2adf17d6 -F tag=br-master-fb84878 -F repo=cms -F token=YOUR_API_TOKEN http://localhost:9292/create/ami
```
