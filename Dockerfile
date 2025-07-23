# syntax=docker/dockerfile:1
FROM golang:1.23-alpine AS anyconf-builder

# Install required packages
RUN apk add --no-cache bash yq
# Install anyconf
RUN go install github.com/anyproto/any-sync-tools/anyconf@latest

# -----------------------------------------------
FROM python:3.11-alpine AS final

# Install required packages
RUN apk add --no-cache \
    bash \
    perl \
    yq \
    py3-yaml \
    docker \
    docker-compose \
    make \
    mongodb \
    redis

# Set up working directory
WORKDIR /app

# Copy files from the project
COPY .env.default .env.default
COPY docker-generateconfig/ /app/docker-generateconfig/
COPY Makefile /app/Makefile

# Copy anyconf from builder
COPY --from=anyconf-builder /go/bin/anyconf /usr/local/bin/anyconf

# Install Python requirements
RUN pip install --no-cache-dir requests==2.32.2

# Create necessary directories
RUN mkdir -p /app/etc /app/storage

# Create a script to run all components
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Create .env.override file from environment variables\n\
if [ -n "$EXTERNAL_LISTEN_HOST" ]; then\n\
    echo "EXTERNAL_LISTEN_HOST=\"$EXTERNAL_LISTEN_HOST\"" >> .env.override\n\
fi\n\
\n\
if [ -n "$EXTERNAL_LISTEN_HOSTS" ]; then\n\
    echo "EXTERNAL_LISTEN_HOSTS=\"$EXTERNAL_LISTEN_HOSTS\"" >> .env.override\n\
fi\n\
\n\
if [ -n "$ANY_SYNC_VERSION" ]; then\n\
    echo "ANY_SYNC_NODE_VERSION=$ANY_SYNC_VERSION" >> .env.override\n\
    echo "ANY_SYNC_FILENODE_VERSION=$ANY_SYNC_VERSION" >> .env.override\n\
    echo "ANY_SYNC_COORDINATOR_VERSION=$ANY_SYNC_VERSION" >> .env.override\n\
    echo "ANY_SYNC_CONSENSUSNODE_VERSION=$ANY_SYNC_VERSION" >> .env.override\n\
fi\n\
\n\
# Generate environment file\n\
python /app/docker-generateconfig/env.py\n\
\n\
# Create directories\n\
mkdir -p ./storage/docker-generateconfig\n\
\n\
# Run anyconf script\n\
bash /app/docker-generateconfig/anyconf.sh\n\
\n\
# Process configurations\n\
bash /app/docker-generateconfig/processing.sh\n\
\n\
# Print client.yml to console\n\
echo "================ CLIENT.YML CONTENT ================"  \n\
cat /app/etc/client.yml \n\
echo "==================================================="  \n\
\n\
# Keep container running\n\
echo "Configuration complete. Container will remain running for you to access files." \n\
tail -f /dev/null\n\
' > /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Set environment variables
ENV ANY_SYNC_VERSION="latest" \
    EXTERNAL_LISTEN_HOST="0.0.0.0" \
    STORAGE_DIR="/app/storage"

VOLUME ["/app/storage", "/app/etc"]

EXPOSE 1001-1006 1011-1016 8000-8006 9000-9001

ENTRYPOINT ["/app/entrypoint.sh"]