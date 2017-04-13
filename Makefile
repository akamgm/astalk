
ZONE=us-central1-a

# Locust, the test harness
LOCUST_INSTANCE_TYPE=n1-standard-8
LOCUST_NODES=3

# System under test cluster
SUT_INSTANCE_TYPE=n1-standard-2
SUT_NODES=3
SUT_MAX_NODES=20

swarm:
	-gcloud container clusters create swarm -m $(LOCUST_INSTANCE_TYPE) --num-nodes=$(LOCUST_NODES) --zone $(ZONE)
	gcloud container clusters get-credentials swarm
	helm init && wait-for-tiller
	helm install --name locust locust/	

sut:
	-gcloud container clusters create sut -m $(SUT_INSTANCE_TYPE) --num-nodes=$(SUT_NODES) --zone $(ZONE)
	gcloud container clusters get-credentials sut
	helm init && wait-for-tiller
	helm install --name traf traefik/	
	helm install --name prom prometheus/	
	helm install --name echo echo/	

auto-sut: sut
	# applies cluster autoscaling on an existing sut cluster
	gcloud alpha container clusters update sut --enable-autoscaling --min-nodes=$(SUT_NODES) --max-nodes=$(SUT_MAX_NODES) --zone=$(ZONE)

delete:
	-gcloud container clusters delete swarm
	-gcloud container clusters delete sut