// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0
import { chromium } from '@playwright/test';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, stat, writeFile, mkdtemp, mkdir, rm } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
const repo = fileURLToPath(new URL('../', import.meta.url)).replace(/\/$/, '');
const { application: app } = JSON.parse(await readFile(`${repo}/tool/runtimes.lock.json`, 'utf8'));
const results = `${repo}/tool/test-results`;
await mkdir(results, { recursive: true });
// Decode the emitted PNG, then inspect it on white so transparent black R
// drawing remains visible. An empty/solid canvas is not evidence of a plot.
async function saveVerifiedPlot(page, kernel) {
  const deadline = performance.now() + 30000;
  let plot;
  while (performance.now() < deadline) {
    plot = await page.evaluate(async kernel => {
      const plot = window.events.filter(e => e.type === 'plot' && e.payload.kernel === kernel).at(-1);
      if (!plot || !plot.payload.png.startsWith('data:image/png;base64,')) return false;
      const image = new Image();
      image.src = plot.payload.png;
      await image.decode();
      if (image.naturalWidth < 2 || image.naturalHeight < 2) return false;
      const canvas = document.createElement('canvas');
      canvas.width = image.naturalWidth; canvas.height = image.naturalHeight;
      const context = canvas.getContext('2d');
      context.fillStyle = 'white'; context.fillRect(0, 0, canvas.width, canvas.height);
      context.drawImage(image, 0, 0);
      const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
      let ink = 0, white = 0;
      for (let i = 0; i < pixels.length; i += 4) {
        if (Math.min(pixels[i], pixels[i + 1], pixels[i + 2]) < 240) ink++;
        else white++;
      }
      if (ink < 100 || white < 100) return false;
      return {png: plot.payload.png, composite: canvas.toDataURL('image/png'),
        width: canvas.width, height: canvas.height, inkPixels: ink, whitePixels: white};
    }, kernel);
    if (plot) break;
    await new Promise(resolve => setTimeout(resolve, 50));
  }
  if (!plot) throw Error(`No nonblank renderable ${kernel} plot within 30 seconds`);
  await writeFile(`${results}/${kernel}-plot.png`, Buffer.from(plot.png.split(',')[1], 'base64'));
  await writeFile(`${results}/${kernel}-plot-white.png`, Buffer.from(plot.composite.split(',')[1], 'base64'));
  const {png, composite, ...facts} = plot;
  await writeFile(`${results}/${kernel}-plot.json`, JSON.stringify(facts, null, 2) + '\n');
}

let temp;
let root = repo;
if (app === 'vitrine') {
  temp = await mkdtemp(`${tmpdir()}/vitrine-smoke-`);
  root = temp;
  execFileSync('python3', ['-c', 'import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])', `${repo}/assets/shinylive-r/engine.zip`, root]);
  const engine = await readFile(`${repo}/lib/runtime/shinylive_engine.dart`, 'utf8');
  const html = engine.split("static String indexHtml() => "+"'".repeat(3))[1].split("'".repeat(3)+';')[0];
  await writeFile(`${root}/index.html`, html);
  const importer = await readFile(`${repo}/lib/features/import/import_controller.dart`, 'utf8');
  const code = importer.split("static const String _sampleShinyliveAppR = "+"'".repeat(3))[1].split("'".repeat(3)+';')[0].replaceAll('\\$', '$');
  await writeFile(`${root}/app.json`, JSON.stringify([{name:'app.R', content:code, type:'text'}]));
}
const server = createServer(async (req, res) => {
  try {
    const path = resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
    if (!path.startsWith(root + '/')) throw Error('outside');
    const file = (await stat(path)).isDirectory() ? path + '/index.html' : path;
    const mime = {'.mjs':'text/javascript','.js':'text/javascript','.html':'text/html','.css':'text/css','.wasm':'application/wasm','.json':'application/json'}[extname(file)] || 'application/octet-stream';
    res.setHeader('Content-Type', mime);
    res.end(await readFile(file));
  } catch { res.writeHead(404);res.end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const origin = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch({args: ['--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE 127.0.0.1']});
try {
  const context = await browser.newContext();
  const external = [];
  await context.route('**/*', route => {
    const url = route.request().url();
    if (!url.startsWith(origin + '/') && !url.startsWith('blob:') && !url.startsWith('data:')) {
      external.push(url);return route.abort();
    }
    return route.continue();
  });
  const page = await context.newPage();
  page.on('console', m => console.log('browser', m.type(), m.text()));
  page.on('pageerror', e => console.log('pageerror', e.message));
  if (app === 'atelier') {
    await page.addInitScript(() => {
      window.events = [];
      window.flutter_inappwebview = {callHandler: (_, event) => window.events.push(event)};
    });
    await page.goto(origin + '/assets/web/index.html');
    await page.waitForFunction(() => window.EtabliKernel, null, {timeout:30000});
    await page.evaluate(() => window.EtabliKernel.start('r'));
    await page.waitForFunction(() => window.EtabliKernel.isReady('r'), null, {timeout:60000});
    await page.evaluate(() => window.EtabliFS.push('r', [{path:'input.txt',b64:btoa('hello')} ]));
    await page.evaluate(() => window.EtabliKernel.stdin('r', 'writeLines("from R", "output.txt"); print(6 * 7)'));
    await page.waitForFunction(() => window.events.some(e => e.type === 'stdout' && e.payload.text.includes('42')));
    const files = await page.evaluate(() => window.EtabliFS.snapshot('r'));
    console.log('R snapshot', files);
    if (!files.some(f => f.path === 'output.txt' && atob(f.b64).includes('from R'))) throw Error('R workspace snapshot failed');
    await page.evaluate(() => window.EtabliKernel.stdin('r', 'plot(1:3, c(2, 4, 3))'));
    await saveVerifiedPlot(page, 'r');
    await page.evaluate(() => window.EtabliKernel.stdin('r', 'stop("expected fixture failure")'));
    await page.waitForFunction(() => window.events.some(e => e.type === 'stderr' && e.payload.text.includes('expected fixture failure')));
    await page.evaluate(() => { window.events = []; });
    await page.evaluate(() => window.EtabliKernel.stdin('r', 'print(7 * 8)'));
    await page.waitForFunction(() => window.events.some(e => e.type === 'stdout' && e.payload.text.includes('56')));
    await page.evaluate(() => window.EtabliKernel.start('python'));
    await page.evaluate(files => window.EtabliFS.push('python', files), files);
    await page.evaluate(code => window.EtabliKernel.stdin('python', code), "import numpy, pandas, scipy, sklearn\nfrom scipy.linalg import solve\nfrom sklearn.linear_model import LinearRegression\nimport matplotlib.pyplot as plt\nassert open(\"output.txt\").read().strip() == \"from R\"\nsolution = solve(numpy.array([[3.,1.],[1.,2.]]), numpy.array([9.,8.]))\nassert numpy.allclose(solution, [2.,3.])\nmodel = LinearRegression().fit(numpy.array([[1.],[2.],[3.]]), numpy.array([3.,5.,7.]))\nassert abs(model.predict(numpy.array([[4.]]))[0] - 9.) < 1e-8\nassert int(pandas.DataFrame({\"x\":[1,2,3]}).x.sum()) == 6\nprint(\"SCIENTIFIC_OK scipy_solve=2,3 sklearn_prediction=9 pandas_sum=6\")\nplt.plot([1, 2], [3, 4])");
    const events = await page.evaluate(() => window.events);
    if (!events.some(e => e.type === 'stdout' && e.payload.text.includes('SCIENTIFIC_OK'))) throw Error('Scientific numerical assertions did not finish');
    await saveVerifiedPlot(page, 'python');
    if (events.some(e => e.type === 'stderr' && /Traceback|Error/.test(e.payload.text))) throw Error('Python execution failed');
  } else {
    await page.goto(origin + '/index.html');
    await page.frameLocator('iframe').first().getByText('Établi Vitrine — sample app').waitFor({timeout:60000});
    await page.frameLocator('iframe').first().locator('#summary').getByText(/Median/).waitFor({timeout:60000});
    await page.screenshot({path:`${results}/vitrine.png`});
  }
  if (external.length) throw Error('External requests: ' + external.join(', '));
  console.log('PASS offline runtime smoke:', app);
} catch (error) {
  for (const context of browser.contexts()) for (const page of context.pages()) {
    for (const frame of page.frames()) console.log('FRAME', frame.url(), (await frame.locator('body').innerText()).slice(0,2000));
    await page.screenshot({path: `${results}/${app}-failure.png`});
  }
  throw error;
} finally {
  await browser.close();
  server.closeAllConnections();
  server.close();
  if (temp) await rm(temp, {recursive:true, force:true});
}
