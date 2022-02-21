#!/bin/bash

PROJNAME=quarkus-coffeeshop

oc new-project $PROJNAME

sleep 2

oc project $PROJNAME

sleep 5

########################################################
# Create the database
########################################################
oc new-app \
  --name=coffeeshopdb \
  --template=postgresql-ephemeral \
  -p POSTGRESQL_USER=coffeeshopadmin \
  -p POSTGRESQL_PASSWORD=coffeeshopadmin \
  -p POSTGRESQL_DATABASE=coffeeshopdb \
  -p DATABASE_SERVICE_NAME=coffeeshopdb

echo "Waiting for the database to be created"
sleep 30

DBPOD=$( oc get pods | grep coffeeshopdb | grep -v deploy | grep Running | awk '{print $1}' )
while [ "${DBPOD}" == "" ]; do
    sleep 5
    DBPOD=$( oc get pods | grep coffeeshopdb | grep -v deploy | grep Running | awk '{print $1}' )
done

sleep 5
echo "Initialising the database"
oc cp init_postgres_db.sh ${DBPOD}:/tmp
oc rsh ${DBPOD} /tmp/init_postgres_db.sh

########################################################
# Setup Kafka
########################################################


echo "Creating the kafka cluster"
oc create -f kafka-instance.yaml
sleep 10

NUMKAFKAS=$( oc get pods | grep "cafe-cluster-kafka" | grep Running | wc -l )
if [ "${NUMKAFKAS}" ne 3 ]; then
    sleep 5
    NUMKAFKAS=$( oc get pods | grep "cafe-cluster-kafka" | grep Running | wc -l )
    
    echo "Number of Kafka containers running: ${NUMKAFKAS}"
fi


echo "Creating the Kafka topics"
oc create -f kafka-topics.yaml

echo "Creating Kafdrop"
oc create -f kafdrop.yaml

sleep 5


########################################################
# Create the deployments
########################################################

echo "Creating the deployments"
cat deployment.yaml | \
    sed 's/DOMAIN/apps-crc.testing/g' | \
    sed 's/NAMESPACE/quarkus-coffeeshop/g' | \
    sed 's/VERSION-BARISTA/5.0.0-SNAPSHOT/g' | \
    sed 's/VERSION-COUNTER/5.0.3-SNAPSHOT/g' | \
    sed 's/VERSION-MOCKER/5.0.1-SNAPSHOT/g' | \
    sed 's/VERSION-INVENTORY/5.0.0-SNAPSHOT/g' | \
    sed 's/VERSION-KITCHEN/5.0.0-SNAPSHOT/g' | \
    sed 's/VERSION-LOYALTY/5.0.1-SNAPSHOT/g' | \
    sed 's/VERSION-WEB/5.0.3-SNAPSHOT/g' | \
    sed 's/KAFKA-CLUSTER/cafe-cluster/g' | \
    oc create -f -

sleep 5

########################################################
# Create the services
########################################################
oc create -f service.yaml

########################################################
# Create the routes
########################################################
cat route.yaml | \
    sed 's/DOMAIN/apps-crc.testing/g' | \
    sed 's/NAMESPACE/quarkus-coffeeshop/g' | \
    oc create -f -


########################################################
# Scale up
########################################################
# Now start scaling everything up.  On my home internet, this crushes
# the network...  it can't download that many images at once.  So only
# start up a few to start with.
#DEPLOYMENTS="quarkuscoffeeshop-web quarkuscoffeeshop-counter quarkuscoffeeshop-barista quarkuscoffeeshop-inventory quarkuscoffeeshop-kitchen quarkuscoffeeshop-customerloyalty"
DEPLOYMENTS="quarkuscoffeeshop-web quarkuscoffeeshop-counter"

for DEPL in ${DEPLOYMENTS}; do
    oc scale deployment ${DEPL} --replicas=1
    sleep 10
done


