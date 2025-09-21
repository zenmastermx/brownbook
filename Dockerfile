# Use the official Node.js runtime as a parent image
FROM node:18-bullseye-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz -o flutter.tar.xz \
    && tar -xf flutter.tar.xz \
    && rm flutter.tar.xz \
    && mv flutter /opt/flutter \
    && /opt/flutter/bin/flutter doctor

# Add Flutter to PATH
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Set the working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production

# Copy the rest of the application code
COPY . .

# Build the Flutter web app
RUN flutter clean && flutter pub get && flutter build web --web-renderer html

# Expose the port (Firebase App Hosting handles this)
# EXPOSE 8080

# Start the application (Firebase App Hosting handles this)
# CMD ["npm", "start"]
