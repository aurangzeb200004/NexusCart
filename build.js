const fs = require('fs');
const path = require('path');

const rootDir = process.cwd();
const indexSrc = path.join(rootDir, 'index.html');

if (!fs.existsSync(indexSrc)) {
  console.error('Error: index.html not found at', indexSrc);
  process.exit(1);
}

const htmlContent = fs.readFileSync(indexSrc, 'utf8');

// 1. Output to standard directories (public, dist, build)
['public', 'dist', 'build'].forEach(dirName => {
  const targetDir = path.join(rootDir, dirName);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }
  fs.writeFileSync(path.join(targetDir, 'index.html'), htmlContent);
});

// 2. Output to .vercel/output (Vercel Build Output API v3)
const vercelOutputDir = path.join(rootDir, '.vercel', 'output');
const vercelStaticDir = path.join(vercelOutputDir, 'static');

if (!fs.existsSync(vercelStaticDir)) {
  fs.mkdirSync(vercelStaticDir, { recursive: true });
}
fs.writeFileSync(path.join(vercelStaticDir, 'index.html'), htmlContent);

const vercelConfig = {
  version: 3,
  routes: [
    { handle: 'filesystem' },
    { src: '/(.*)', dest: '/index.html' }
  ]
};

fs.writeFileSync(
  path.join(vercelOutputDir, 'config.json'),
  JSON.stringify(vercelConfig, null, 2)
);

// 3. Fallback for container absolute path /vercel/output
try {
  if (fs.existsSync('/vercel')) {
    const linuxOutput = '/vercel/output';
    const linuxStatic = path.join(linuxOutput, 'static');
    if (!fs.existsSync(linuxStatic)) {
      fs.mkdirSync(linuxStatic, { recursive: true });
    }
    fs.writeFileSync(path.join(linuxStatic, 'index.html'), htmlContent);
    fs.writeFileSync(
      path.join(linuxOutput, 'config.json'),
      JSON.stringify(vercelConfig, null, 2)
    );
  }
} catch (e) {
  // Ignore in local environments
}

console.log('✓ Vercel build successful: deployed to .vercel/output (v3), public/, dist/, and build/');
