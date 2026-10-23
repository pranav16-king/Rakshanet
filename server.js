const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = process.env.PORT || 3000;
const ROOT_DIR = __dirname;
const MOBILE_DIR = path.join(ROOT_DIR, 'mobile');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.pdf': 'application/pdf',
};

const server = http.createServer((req, res) => {
  let reqPath = decodeURI(req.url.split('?')[0]);

  // Route aliases
  if (reqPath === '/' || reqPath === '/preview' || reqPath === '/index.html') {
    reqPath = '/mobile/preview.html';
  } else if (reqPath === '/graph') {
    reqPath = '/graphify-out/graph.html';
  }

  // Attempt resolution from project root, then mobile folder
  let filePath = path.join(ROOT_DIR, reqPath);
  if (!fs.existsSync(filePath)) {
    filePath = path.join(MOBILE_DIR, reqPath);
  }

  // Check if directory
  if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
    const previewInDir = path.join(filePath, 'preview.html');
    const indexInDir = path.join(filePath, 'index.html');
    if (fs.existsSync(previewInDir)) {
      filePath = previewInDir;
    } else if (fs.existsSync(indexInDir)) {
      filePath = indexInDir;
    }
  }

  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end(`404 Not Found: ${req.url}`);
    return;
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(`Server Error: ${err.message}`);
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(content);
  });
});

server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log('\n========================================================');
  console.log(' 📡 RakshaNet — Dev Server Running');
  console.log('========================================================');
  console.log(` 🌐 Local URL:  ${url}`);
  console.log(` 📱 Mobile UI:  ${url}/mobile/preview.html`);
  console.log(` 📊 Knowledge:  ${url}/graph`);
  console.log('========================================================\n');

  // Launch Microsoft Edge browser automatically
  const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
  const edgeCmd = fs.existsSync(edgePath)
    ? `"${edgePath}" --new-window "${url}"`
    : `start ${url}`;

  exec(edgeCmd, (err) => {
    if (!err) {
      console.log(' 🚀 Microsoft Edge launched successfully.\n');
    }
  });
});
