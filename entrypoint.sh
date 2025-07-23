#!/bin/bash
set -e

# Create .env.override file from environment variables
if [ -n "$EXTERNAL_LISTEN_HOST" ]; then
    echo "EXTERNAL_LISTEN_HOST=\"$EXTERNAL_LISTEN_HOST\"" >> .env.override
fi

if [ -n "$EXTERNAL_LISTEN_HOSTS" ]; then
    echo "EXTERNAL_LISTEN_HOSTS=\"$EXTERNAL_LISTEN_HOSTS\"" >> .env.override
fi

if [ -n "$ANY_SYNC_VERSION" ]; then
    echo "ANY_SYNC_NODE_VERSION=$ANY_SYNC_VERSION" >> .env.override
    echo "ANY_SYNC_FILENODE_VERSION=$ANY_SYNC_VERSION" >> .env.override
    echo "ANY_SYNC_COORDINATOR_VERSION=$ANY_SYNC_VERSION" >> .env.override
    echo "ANY_SYNC_CONSENSUSNODE_VERSION=$ANY_SYNC_VERSION" >> .env.override
fi

# Generate environment file
python /app/docker-generateconfig/env.py

# Create directories
mkdir -p ./storage/docker-generateconfig

# Run anyconf script
bash /app/docker-generateconfig/anyconf.sh

# Process configurations
bash /app/docker-generateconfig/processing.sh

# Print client.yml to console
echo "================ CLIENT.YML CONTENT ================"
cat /app/etc/client.yml
echo "==================================================="

# Keep container running
echo "Configuration complete. Container will remain running for you to access files."
tail -f /dev/null