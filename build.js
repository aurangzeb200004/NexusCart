const fs = require('fs');
const path = require('path');

const rootDir = __dirname;
const indexSrc = path.join(rootDir, 'index.html');

['public', 'dist', 'build'].forEach(dirName => {
  const targetDir = path.join(rootDir, dirName);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }
  fs.copyFileSync(indexSrc, path.join(targetDir, 'index.html'));
});

console.log('✓ Vercel build successful: index.html synced to root, public/, dist/, and build/');
