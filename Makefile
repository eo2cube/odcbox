# You can follow the steps below in order to get yourself a local ODC.
# Once running, you can access a Jupyter environment 
# at 'http://localhost' with password 'secretpassword'

# 1. Get the pathrows file
download-pathrows-file:
	wget https://landsat.usgs.gov/sites/default/files/documents/WRS2_descending.zip -O ./data/wrs2_descending.zip

# 2. Start your Docker environment
up:
	docker-compose up

# 3. Prepare the database
initdb:
	docker-compose exec jupyter datacube -v system init
	docker-compose exec jupyter datacube product add /opt/odc/docs/config_samples/dataset_types/ls_usgs.yaml

# 4. Index a dataset (just an example, you can change the extents)
index:
	# Note that you need environment variables ODC_ACCESS_KEY and ODC_SECRET_KEY set.
	# These need to be valid AWS keys. KEEP THEM SECRET, KEEP THEM SAFE!

	docker-compose exec jupyter bash -c \
		"cd /opt/odc/scripts && python3 ./autoIndex.py \
			-p '/opt/odc/data/wrs2_descending.zip' \
			-e '146.30,146.83,-43.54,-43.20'"

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

# Blow it all away and start again. First start the stack with `make up`
load-from-scratch: initdb download-pathrows-file index

# Update S3 template (this is owned by FrontierSI)
update-s3:
	aws s3 cp opendatacube-test.yml s3://cubeinabox/ --acl public-read

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
