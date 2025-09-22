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

# Copy package files first for better caching
COPY package*.json ./

# Install Node.js dependencies (if any)
RUN npm ci --only=production || echo "No dependencies to install"

# Copy the application code
COPY . .

# Build the Flutter web app
RUN flutter clean && flutter pub get && flutter build web --web-renderer html

# Create a simple HTTP server script optimized for Firebase App Hosting
RUN cat > server.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = parseInt(process.env.PORT) || 8080;
const HOST = '0.0.0.0'; // Firebase App Hosting requires listening on all interfaces

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'application/font-woff',
  '.woff2': 'application/font-woff2',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'application/font-otf'
};

function serveFile(filePath, res) {
  // Security check to prevent directory traversal
  const safePath = path.normalize(filePath).replace(/^(\.\.[\/\\])+/, '');
  const fullPath = path.join(__dirname, 'build/web', safePath);

  fs.readFile(fullPath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // File not found, serve index.html for SPA routing
        fs.readFile(path.join(__dirname, 'build/web/index.html'), (err2, data2) => {
          if (err2) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('File not found!');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data2);
          }
        });
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end(`Server Error: ${err.code}`);
      }
    } else {
      const ext = path.extname(fullPath).toLowerCase();
      const mimeType = mimeTypes[ext] || 'application/octet-stream';

      res.writeHead(200, {
        'Content-Type': mimeType,
        'Cache-Control': 'public, max-age=31536000', // Cache static assets for 1 year
        'X-Content-Type-Options': 'nosniff'
      });
      res.end(data);
    }
  });
}

const server = http.createServer((req, res) => {
  const pathname = url.parse(req.url).pathname;

  // Add health check endpoint for Firebase App Hosting
  if (pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  // Serve static files
  serveFile(pathname, res);
});

server.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}/`);
  console.log(`Health check available at http://${HOST}:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
EOF

# Expose the port
EXPOSE 8080

# Set environment variables for Firebase App Hosting
ENV PORT=8080

# Start the HTTP server
CMD ["node", "server.js"]
