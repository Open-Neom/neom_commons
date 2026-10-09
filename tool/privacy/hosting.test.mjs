import assert from 'node:assert/strict';
import {readFile, readdir} from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';

// Opt-in integration checks; no account, production request or deployment.
// NEOM_PRIVACY_APPS_ROOT=/path/to/codebase_flutter node --test tool/privacy/hosting.test.mjs
// Optional: PRIVACY_GIGMEOUT_URL=http://127.0.0.1:5000 (equivalently EMXI/CYBERNEOM).
const appsRoot = process.env.NEOM_PRIVACY_APPS_ROOT;
const route = '/politica-de-privacidad/';
const destination = `${route}index.html`;
const readJson = async file => JSON.parse(await readFile(file, 'utf8'));
const internalMarkers = /borrador|reviewNotes|INTERNAL-REVIEW-CANARY|PRIVATE-CANARY|Pendiente de confirmar|pendiente de (?:aprobación|validación)|revisión interna/iu;
async function readOptionalText(file) {
  try { return await readFile(file, 'utf8'); }
  catch (error) {
    if (error.code === 'ENOENT') return undefined;
    throw error;
  }
}
async function assertNoBundledReviewFile(directory) {
  let entries;
  try { entries = await readdir(directory, {withFileTypes: true}); }
  catch (error) {
    if (error.code === 'ENOENT') return; // A fresh clone need not contain a build.
    throw error;
  }
  for (const entry of entries) {
    assert.notEqual(entry.name, 'privacy_policy.review.json', 'Internal review notes must not enter public files');
    if (entry.isDirectory()) await assertNoBundledReviewFile(path.join(directory, entry.name));
  }
}

for (const app of ['Gigmeout', 'EMXI', 'Cyberneom']) {
  test(`${app}: generated policy and both Hosting entrypoints agree`, {skip: !appsRoot}, async () => {
    const appRoot = path.join(appsRoot, app);
    const properties = await readJson(path.join(appRoot, 'assets/properties.json'));
    const metadataSource = await readFile(path.join(appRoot, 'assets/privacy_policy.json'), 'utf8');
    const metadata = JSON.parse(metadataSource);
    assert.equal(Object.hasOwn(metadata, 'reviewNotes'), false, 'Public metadata must not contain internal review notes');
    const builtMetadataSource = await readOptionalText(path.join(appRoot, 'build/web/assets/assets/privacy_policy.json'));
    if (builtMetadataSource !== undefined) {
      assert.equal(Object.hasOwn(JSON.parse(builtMetadataSource), 'reviewNotes'), false,
        'Bundled metadata must not contain internal review notes');
      assert.ok(builtMetadataSource === metadataSource, 'Bundled metadata must match its source exactly');
    }
    const html = await readFile(path.join(appRoot, 'web', destination), 'utf8');
    assert.match(html, /<html\b[^>]*lang="es"/);
    assert.match(html, /<meta\b[^>]*name="viewport"/);
    assert.ok(html.includes(properties.appName));
    assert.ok(html.includes(metadata.privacyEmail || properties.contactEmail));
    assert.ok(html.includes(properties.privacyPolicyUrl));
    assert.doesNotMatch(html, /<script\b|flutter_bootstrap|<iframe\b|<form\b|\{\{[A-Z_]+\}\}/i);
    assert.doesNotMatch(html, /service_account|private_key|stripeSecretKey|clientSecret/i);
    assert.doesNotMatch(html, /reviewNotes|INTERNAL-REVIEW-CANARY|PRIVATE-CANARY/);
    assert.ok(['draft', 'published', 'approved'].includes(metadata.status));
    assert.ok(html.includes(`name="privacy-policy-status" content="${metadata.status}"`));
    const anchors = [...html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]);
    assert.equal(anchors.length, new Set(anchors).size, 'Duplicate HTML anchor IDs');
    for (const [, target] of html.matchAll(/href="#([^"]+)"/g)) {
      assert.ok(anchors.includes(target), `Missing anchor #${target}`);
    }
    if (metadata.status === 'draft') {
      assert.match(html, /noindex/);
      assert.match(html, /borrador/i);
    } else {
      assert.doesNotMatch(html, /noindex|<aside\b|Borrador|Pendiente de confirmar|\{\{|\}\}/);
      assert.ok(metadata.controllerName);
      assert.ok(metadata.privacyEmail);
      assert.equal(new URL(properties.privacyPolicyUrl).protocol, 'https:');
    }
    const pubspec = await readFile(path.join(appRoot, 'pubspec.yaml'), 'utf8');
    assert.ok(/- assets\/$/m.test(pubspec) || /- assets\/privacy_policy\.md$/m.test(pubspec));
    assert.doesNotMatch(pubspec, /privacy_policy\.review\.json|^\s*-\s*['"]?(?:\.\/)?legal(?:\/|['"]?\s*$)/m,
      'Local legal review notes must stay outside Flutter assets');
    // legal/privacy_policy.review.json is optional and intentionally untracked.
    // Only enforce that it is absent from assets and any built/public output.
    for (const publicDirectory of ['assets', 'web', 'build/web']) {
      await assertNoBundledReviewFile(path.join(appRoot, publicDirectory));
    }

    for (const configName of ['firebase.json', 'web/firebase.json']) {
      const {hosting} = await readJson(path.join(appRoot, configName));
      const configDir = path.dirname(path.join(appRoot, configName));
      assert.equal(path.resolve(configDir, hosting.public), path.join(appRoot, 'build/web'));
      assert.ok(hosting.ignore.includes('**/privacy_policy.review.json'), 'Hosting must exclude internal review notes');
      // A source glob also matches the trailing slash and causes a redirect loop.
      const redirect = hosting.redirects.find(item => item.regex === '^/politica-de-privacidad$');
      assert.equal(redirect?.destination, route);
      assert.equal(redirect?.type, 301);
      const policyIndex = hosting.rewrites.findIndex(item => item.source === route);
      const fallbackIndex = hosting.rewrites.findIndex(item => item.source === '**');
      assert.ok(policyIndex >= 0 && policyIndex < fallbackIndex);
      assert.equal(hosting.rewrites[policyIndex].destination, destination);
      const headers = hosting.headers.find(item => item.source === '/politica-de-privacidad{,/**}')?.headers;
      assert.ok(headers);
      const byName = Object.fromEntries(headers.map(({key, value}) => [key.toLowerCase(), value]));
      assert.equal(byName['content-type'], 'text/html; charset=utf-8');
      assert.match(byName['cache-control'], /no-cache/);
      assert.equal(byName['x-content-type-options'], 'nosniff');
      const assetHeaders = hosting.headers.find(item => item.source === '/assets/assets/privacy_policy.{md,json}')?.headers;
      assert.ok(assetHeaders, 'Privacy Markdown and metadata need explicit cache controls');
      const assetCache = assetHeaders.find(({key}) => key.toLowerCase() === 'cache-control')?.value;
      assert.ok(assetCache, 'Privacy asset Cache-Control header is missing');
      const directives = new Set(assetCache.toLowerCase().split(',').map(value => value.trim()));
      assert.ok(directives.has('no-cache') && directives.has('max-age=0'),
        'Privacy assets must revalidate without a positive cache lifetime');
    }
  });

  const baseUrl = process.env[`PRIVACY_${app.toUpperCase()}_URL`];
  test(`${app}: public HTTP route serves HTML without Flutter and preserves SPA routes`, {skip: !baseUrl}, async () => {
    const base = new URL(baseUrl);
    assert.ok(['127.0.0.1', 'localhost', '[::1]'].includes(base.hostname), 'Use a local Hosting emulator only');
    const request = suffix => fetch(new URL(suffix, base), {redirect: 'manual', signal: AbortSignal.timeout(10000)});
    const redirect = await request(route.slice(0, -1));
    assert.equal(redirect.status, 301);
    assert.equal(new URL(redirect.headers.get('location'), base).pathname, route);
    for (const url of [route, destination]) {
      const response = await request(url);
      assert.equal(response.status, 200, url);
      assert.match(response.headers.get('content-type'), /text\/html/);
      assert.match(response.headers.get('cache-control'), /no-cache/);
      const html = await response.text();
      assert.match(html, /Política de privacidad/);
      assert.doesNotMatch(html, /<script\b|flutter_bootstrap/i);
      assert.match(html, /name="privacy-policy-status" content="(?:published|approved)"/);
      assert.doesNotMatch(html, /noindex|<aside\b|Borrador|Pendiente de confirmar|reviewNotes|INTERNAL-REVIEW-CANARY|\{\{|\}\}/);
    }
    for (const extension of ['md', 'json']) {
      const response = await request(`/assets/assets/privacy_policy.${extension}`);
      assert.equal(response.status, 200, `privacy_policy.${extension}`);
      const body = await response.text();
      assert.ok(!internalMarkers.test(body), 'Public privacy assets must not expose drafts or internal review notes');
      if (extension === 'json') {
        const metadata = JSON.parse(body);
        assert.ok(['published', 'approved'].includes(metadata.status), 'Public metadata must describe a published policy');
        assert.equal(Object.hasOwn(metadata, 'reviewNotes'), false, 'Public JSON must not expose internal review notes');
      } else {
        assert.ok(/^##\s+/m.test(body), 'Expected policy Markdown, not an SPA fallback');
      }
      if (appsRoot) {
        const source = await readFile(path.join(appsRoot, app, `assets/privacy_policy.${extension}`), 'utf8');
        assert.ok(body === source, 'Public privacy asset must match its source exactly');
      }
      // Running emulators can use older config snapshots; assert the new
      // asset cache header in the static config checks above, not over HTTP.
    }
    const privateReview = await request('/legal/privacy_policy.review.json');
    assert.ok([200, 403, 404].includes(privateReview.status), 'Unexpected response for private review path');
    const privateBody = await privateReview.text();
    assert.ok(!/reviewNotes|INTERNAL-REVIEW-CANARY|PRIVATE-CANARY/iu.test(privateBody),
      'Private review path must not disclose internal notes');
    if (privateReview.status === 200) {
      assert.ok(/text\/html/iu.test(privateReview.headers.get('content-type') ?? '')
        && privateBody.includes('flutter_bootstrap'), 'Only an SPA fallback is allowed for the private review path');
    }
    const spa = await request('/audioPlayer');
    assert.equal(spa.status, 200);
    assert.match(await spa.text(), /flutter_bootstrap/);
  });
}
