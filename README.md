# Upgrade Replica Placement Policy (RPP) for Kafka Topics
##bOverview
When creating a Kafka topic using the Mongey Terraform Provider, the specified number of replicas can override the default replica placement policy (RPP) defined in the Kafka broker. This script, `upgrade-rpp-new-topic.sh`, allows you to automate the process of updating the RPP to your desired configuration, primarily setting the partition leader in the primary region.

## Prerequisites
1. Confluent Platform tools: Ensure that the Confluent Platform command-line tools (`kafka-configs`, `confluent-rebalancer`, etc.) are installed and available in the system's PATH.

2. Topic List: Maintain a file named `topics.txt` that contains the list of topic names, one per line, for which the RPP should be updated.

3. Configuration Files: The following configuration files must be present in the same directory as the script:

- `placement-multi-region-rpp-east-step-1.json`: Initial RPP configuration where the desired number of replicas and observers are specified primarily for the us-east-2 region.

- `placement-multi-region-rpp-east-step-2.json`: Final RPP configuration which spreads replicas across two regions: `us-east-2` and `us-west-2`.

## Usage
1. Ensure that the script `upgrade-rpp-new-topic.sh` has the required execute permissions:


```
chmod +x upgrade-rpp-new-topic.sh
```
2. Execute the script:


```
./upgrade-rpp-new-topic.sh
```
3. The script will go through several steps, including:

- Checking for concurrent rebalance operations.
- Modifying the replica placement policy using the provided JSON configuration files.
- Reassigning partitions.
- Monitoring reassignment status.
- Finalizing the reassignment.
- Validating the leader placement.
