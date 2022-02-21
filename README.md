# quarkus-coffee-shop-redux

A reduction of the Quarkus Coffeeshop, available here:

https://github.com/quarkuscoffeeshop/

The need for Ansible and PGO makes it difficult to install in all circumstances.  So I've simplified the installation (although it is less flexible).

Full acknowledgement goes to Jeremy Davis from Red Hat for all the amazing work on the Coffee shop application.

INSTALLATION

You must do the following before running setup.sh:

* Login to openshift/kubernetes  (oc login -u kubeadmin <url>)
* Install the Red Hat Kafka Operator

Finally, run setup.sh and it does the rest.  setup.sh is pretty easy to understand, so feel free to "cat" it, and only run the bits you need.
