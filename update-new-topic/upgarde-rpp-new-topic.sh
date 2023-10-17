#!/bin/bash

# Variables
BROKER="broker-east-3:19093"
TOPICS_FILE="topics.txt"
NEW_RPP_STEP_1="placement-multi-region-rpp-east-step-1.json"
NEW_RPP_STEP_2="placement-multi-region-rpp-east-step-2.json"

# Generate comma-separated list of topics
TOPICS_LIST=$(paste -sd, - < $TOPICS_FILE)

echo "Check if there is a concurrent rebalance before updating Topics config"
# Check if there is a concurrent rebalance before updating Topics config
while true; do
    STATUS_OUTPUT=$(confluent-rebalancer status --bootstrap-server $BROKER)
    echo "Rebalance Status: $STATUS_OUTPUT"

    # Check for the specific 'Error' to see if rebalance is completed
    if [[ $STATUS_OUTPUT == *"No rebalance is currently in progress."* ]]; then
        break
    else
        echo "Waiting for rebalance to complete..."
        sleep 60
    fi
done


# Step 1: Modify the Replica Placement Policy
echo "Step 1: Modify the Replica Placement Policy"
while read topic; do
    kafka-configs --bootstrap-server $BROKER --entity-name $topic --entity-type topics --alter --replica-placement $NEW_RPP_STEP_1
done < $TOPICS_FILE

# Step 2: Reassignment of Partitions
echo "Step 2: Reassignment of Partitions"
confluent-rebalancer execute --bootstrap-server $BROKER --replica-placement-only --topics $TOPICS_LIST --force --throttle 10000000 --verbose

# Step 3: Monitor Reassignment status
echo "Step 3: Monitor Reassignment status"
while true; do
    STATUS_OUTPUT=$(confluent-rebalancer status --bootstrap-server $BROKER)
    echo "Rebalance Status: $STATUS_OUTPUT"

    # Check for the specific 'Error' to see if rebalance is completed
    if [[ $STATUS_OUTPUT == *"No rebalance is currently in progress."* ]]; then
        break
    else
        echo "Waiting for rebalance to complete..."
        sleep 60
    fi
done

# Step 4: Finalize the Reassignment
echo "Step 4: Finalize the Reassignment"
confluent-rebalancer finish --bootstrap-server $BROKER

# Step 5: Validate Leader placement
# Note: This step just gives the command. Actual monitoring would involve integrating this output with a tool/dashboard.
echo "Step 5: Validate Leader placement"
kafka-topics --bootstrap-server $BROKER --describe | grep Leader | awk '{ print "Broker " $6 }' | sort -k 2n | uniq -c

# Step 6: Modify the Replica Placement Policy to spread Replicas across the 2 regions (west and east)
echo "Step 6: Modify the Replica Placement Policy to spread Replicas across the 2 regions (west and east)"
while read topic; do
    kafka-configs --bootstrap-server $BROKER --entity-name $topic --entity-type topics --alter --replica-placement $NEW_RPP_STEP_2
done < $TOPICS_FILE

# Step 7: Reassignment of Partitions
echo "Step 7: Reassignment of Partitions"
confluent-rebalancer execute --bootstrap-server $BROKER --replica-placement-only --topics $TOPICS_LIST --force --throttle 10000000 --verbose

# Step 8: Monitor Reassignment status
echo "Step 8: Monitor Reassignment status"
while true; do
    STATUS_OUTPUT=$(confluent-rebalancer status --bootstrap-server $BROKER)
    echo "Rebalance Status: $STATUS_OUTPUT"

    # Check for the specific 'Error' to see if rebalance is completed
    if [[ $STATUS_OUTPUT == *"No rebalance is currently in progress."* ]]; then
        break
    else
        echo "Waiting for rebalance to complete..."
        sleep 60
    fi
done

# Step 9: Finalize the Reassignment
echo "Step 9: Finalize the Reassignment"
confluent-rebalancer finish --bootstrap-server $BROKER

# Step 10: Validate Leader placement
# Note: This step just gives the command. Actual monitoring would involve integrating this output with a tool/dashboard.
echo "Step 10: Validate Leader placement"
kafka-topics --bootstrap-server $BROKER --describe | grep Leader | awk '{ print "Broker " $6 }' | sort -k 2n | uniq -c

# Print completion message
echo "Upgrade Topic Replicas Placement Policy steps completed."
