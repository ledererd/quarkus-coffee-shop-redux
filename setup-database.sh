#!/bin/bash
########################################################
# Since we're using an emphemeral instance of postgres, anytime the
# pod bounces, we lose the schema inside of it.  Use this script
# to regenerate it.
#
# NOTE:  The "setup.sh" script also creates the schema, so you
# don't have to run this script from a fresh install.
########################################################

PROJNAME=quarkus-coffeeshop

oc project $PROJNAME


########################################################
# Create the database
########################################################

DBPOD=$( oc get pods | grep coffeeshopdb | grep -v deploy | grep Running | awk '{print $1}' )
while [ "${DBPOD}" == "" ]; do
    sleep 5
    DBPOD=$( oc get pods | grep coffeeshopdb | grep -v deploy | grep Running | awk '{print $1}' )
done

sleep 5
echo "Initialising the database"
oc cp init_postgres_db.sh ${DBPOD}:/tmp
oc rsh ${DBPOD} /tmp/init_postgres_db.sh

