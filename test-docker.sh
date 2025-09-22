#!/bin/bash

echo "Testing Docker build locally..."

# Build the Docker image
echo "Building Docker image..."
docker build -t brownbook-test .

# Run the container
echo "Running container on port 8080..."
docker run -p 8080:8080 -e PORT=8080 brownbook-test &

# Wait a moment for the server to start
sleep 5

# Test the health endpoint
echo "Testing health endpoint..."
curl -f http://localhost:8080/health

if [ $? -eq 0 ]; then
    echo "✅ Health check passed!"
    echo "✅ Docker container is working correctly!"
    echo "✅ Server is listening on port 8080"
else
    echo "❌ Health check failed"
    echo "❌ There may be an issue with the Docker configuration"
fi

# Clean up
echo "Cleaning up..."
docker stop $(docker ps -q --filter ancestor=brownbook-test)
docker rmi brownbook-test
