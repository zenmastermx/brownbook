##########
# Builder stage: install Flutter and build the web app
##########
FROM debian:bullseye-slim AS builder

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz -o flutter.tar.xz \
    && tar -xf flutter.tar.xz \
    && rm flutter.tar.xz \
    && mv flutter /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app

# Copy the project
COPY . .

# Build Flutter web (release)
RUN flutter config --no-analytics \
    && flutter pub get \
    && flutter build web --web-renderer html --release

##########
# Runtime stage: lightweight Node image to serve static files
##########
FROM node:18-alpine

WORKDIR /app

# Copy only built web assets
COPY --from=builder /app/build/web /app/build/web

# Minimal HTTP server with SPA routing and health endpoint
RUN cat > server.js << 'EOF'
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = Number(process.env.PORT) || 8080;
const HOST = '0.0.0.0';
const ROOT = path.join(__dirname, 'build/web');

const mimeTypes = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'text/javascript; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.eot': 'application/vnd.ms-fontobject',
  '.otf': 'font/otf'
};

function send(res, status, headers, body) {
  res.writeHead(status, headers);
  res.end(body);
}

function serveIndex(res) {
  const indexPath = path.join(ROOT, 'index.html');
  fs.readFile(indexPath, (err, data) => {
    if (err) return send(res, 500, { 'Content-Type': 'text/plain' }, 'index.html missing');
    send(res, 200, { 'Content-Type': 'text/html; charset=UTF-8', 'Cache-Control': 'no-cache' }, data);
  });
}

function serveStatic(filePath, res) {
  const ext = path.extname(filePath).toLowerCase();
  const mime = mimeTypes[ext] || 'application/octet-stream';
  fs.readFile(filePath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') return serveIndex(res);
      return send(res, 500, { 'Content-Type': 'text/plain' }, `Server Error: ${err.code}`);
    }
    const headers = { 'Content-Type': mime, 'X-Content-Type-Options': 'nosniff' };
    if (ext && ext !== '.html') headers['Cache-Control'] = 'public, max-age=31536000, immutable';
    send(res, 200, headers, data);
  });
}

const server = http.createServer((req, res) => {
  try {
    const { pathname = '/' } = url.parse(req.url || '/');

    if (pathname === '/health') {
      return send(res, 200, { 'Content-Type': 'application/json' }, JSON.stringify({ status: 'ok' }));
    }

    let requestedPath = decodeURI(pathname);
    requestedPath = path.posix.normalize(requestedPath).replace(/^\/+/, '');
    if (requestedPath.endsWith('/')) requestedPath += 'index.html';

    const absolutePath = path.join(ROOT, requestedPath);
    if (!absolutePath.startsWith(ROOT)) {
      return send(res, 400, { 'Content-Type': 'text/plain' }, 'Bad request');
    }

    if (!path.extname(absolutePath)) {
      return serveIndex(res);
    }

    serveStatic(absolutePath, res);
  } catch (e) {
    send(res, 500, { 'Content-Type': 'text/plain' }, 'Unexpected server error');
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});

process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});
EOF

EXPOSE 8080

# Cloud Run provides PORT. Node script defaults to 8080 when not set.
CMD ["node", "server.js"]

