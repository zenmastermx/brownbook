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

# Copy the application code
COPY . .

# Build the Flutter web app
RUN flutter clean && flutter pub get && flutter build web --web-renderer html

# Create a simple HTTP server script
RUN cat > server.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 8080;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.wav': 'audio/wav',
  '.mp4': 'video/mp4',
  '.woff': 'application/font-woff',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'application/font-otf',
  '.svg': 'application/image/svg+xml'
};

const server = http.createServer((req, res) => {
  let pathname = url.parse(req.url).pathname;

  // Default to index.html for SPA routing
  if (pathname === '/') {
    pathname = '/index.html';
  }

  const safeSuffix = path.normalize(pathname).replace(/^(\.\.[\/\\])+/, '');
  const filePath = path.join(__dirname, 'build/web', safeSuffix);

  fs.readFile(filePath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        // File not found, serve index.html for SPA routing
        fs.readFile(path.join(__dirname, 'build/web/index.html'), (err2, data2) => {
          if (err2) {
            res.writeHead(404);
            res.end('File not found!');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data2);
          }
        });
      } else {
        res.writeHead(500);
        res.end(`Server Error: ${err.code}`);
      }
    } else {
      const ext = path.extname(filePath).toLowerCase();
      const mimeType = mimeTypes[ext] || 'application/octet-stream';

      res.writeHead(200, {
        'Content-Type': mimeType,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      });
      res.end(data);
    }
  });
});

server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}/`);
});
EOF

# Expose the port
EXPOSE 8080

# Start the HTTP server
CMD ["node", "server.js"]
