# You can follow the steps below in order to get yourself a local ODC.
# Once running, you can access a Jupyter environment 
# at 'http://localhost' with password 'secretpassword'

# 1. Start your Docker environment
up:
	docker-compose up

# 2. Prepare the database
init:
	docker-compose exec jupyter datacube -v system init

# 3. Add a product definition for Sentinel-2
product:
	docker-compose exec jupyter \
		datacube product add https://raw.githubusercontent.com/digitalearthafrica/config/master/products/esa_s2_l2a.yaml

# 4. Index some data (just an example, you can change the extents)
index:
	docker-compose exec jupyter \
		bash -c \
		" \
			stac-to-dc \
			--bbox='25,20,35,30' \
			--collections='sentinel-s2-l2a-cogs' \
			--datetime='2020-01-01/2020-03-31' \
			s2_l2a \
		"

# Some extra commands to help in managing things.
# Rebuild the image
build:
	docker-compose build

# Start an interactive shell
shell:
	docker-compose exec jupyter bash

# Delete everything
clear:
	docker-compose stop
	docker-compose rm -fs

# Update S3 template (this is owned by Digital Earth Australia)
upload-s3:
	aws s3 cp cube-in-a-box-cloudformation.yml s3://opendatacube-cube-in-a-box/ --acl public-read

# This section can be used to deploy onto CloudFormation instead of the 'magic link'
create-infra:
	aws cloudformation create-stack \
		--region ap-southeast-2 \
		--stack-name odc-test \
		--template-body file://opendatacube-test.yml \
		--parameter file://parameters.json \
		--tags Key=Name,Value=OpenDataCube \
		--capabilities CAPABILITY_NAMED_IAM

update-infra:
	aws cloudformation update-stack \
		--stack-name odc-test \
		--template-body file://opendatacube-test.yml \
		--parameter file://parameters.json \
		--tags Key=Name,Value=OpenDataCube \
		--capabilities CAPABILITY_NAMED_IAM
