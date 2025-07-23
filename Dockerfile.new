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
    make \
    git

# Set up working directory
WORKDIR /app

# Copy files from the project
COPY . .
COPY --from=anyconf-builder /go/bin/anyconf /usr/local/bin/anyconf

# Install Python requirements
RUN pip install --no-cache-dir requests==2.32.2

# Ensure Makefile is executable
RUN chmod +x Makefile

# Run make start and log client.yml
CMD make start && \
    echo "================ CLIENT.YML CONTENT ================" && \
    cat ./etc/client.yml && \
    echo "==================================================="