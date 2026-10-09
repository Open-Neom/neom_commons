import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';
import {LEGAL_DOCUMENTS, prepareDocument} from '../privacy/generate.mjs';

const appsRoot = process.env.NEOM_LEGAL_APPS_ROOT;
const apps = {Gigmeout: 'gigmeout.com', Emxi: 'emxi.org', Cyberneom: 'cyberneom.xyz'};
const forbidden = /<script\b|<iframe\b|<form\b|flutter_bootstrap|\{\{|\}\}|PRIVATE-CANARY|INTERNAL-REVIEW-CANARY|reviewNotes|private_key|stripeSecretKey|Borrador|Pendiente de confirmar/iu;

function verifyPage(html, document, domain) {
  const definition = LEGAL_DOCUMENTS[document];
  assert.ok(html.includes(`<h1>${definition.title}</h1>`));
  assert.ok(html.includes(`rel="canonical" href="https://${domain}${definition.route}"`));
  assert.ok(html.includes(`mailto:contacto@${domain}`));
  assert.match(html, /<html lang="es">/);
  assert.match(html, /name="viewport"/);
  assert.doesNotMatch(html, forbidden);
  assert.equal((html.match(/<h1>/g) || []).length, 1);
  for (const target of Object.values(LEGAL_DOCUMENTS)) {
    assert.ok(html.includes(`href="https://${domain}${target.route}"`));
  }
  const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]);
  assert.equal(ids.length, new Set(ids).size);
  for (const [, anchor] of html.matchAll(/href="#([^"]+)"/g)) assert.ok(ids.includes(anchor));
  for (const otherDomain of Object.values(apps)) {
    if (otherDomain !== domain) assert.ok(!html.includes(`mailto:contacto@${otherDomain}`));
  }
  if (document === 'accountDeletion') {
    assert.match(html, /sin instalar la app ni iniciar sesión/);
    assert.match(html, /debes enviarlo/);
    assert.match(html, /Qué puede conservarse/);
    assert.match(html, /Configuración → Cuenta → Eliminar cuenta/);
  }
}

for (const [app, domain] of Object.entries(apps)) {
  for (const document of Object.keys(LEGAL_DOCUMENTS)) {
    test(`${app}: ${document} public artifact matches its source and exposes only public data`, {skip: !appsRoot}, async () => {
      const appDir = path.join(appsRoot, app);
      const generated = await prepareDocument({appDir, document, requirePublished: true});
      const html = await readFile(generated.outputPath, 'utf8');
      assert.ok(html === generated.html, 'Generated public page is stale');
      verifyPage(html, document, domain);
    });
  }
  const baseUrl = process.env[`LEGAL_${app.toUpperCase()}_URL`];
  test(`${app}: local Hosting serves public routes and redirects without authentication`, {skip: !baseUrl}, async () => {
    const base = new URL(baseUrl);
    assert.ok(['127.0.0.1', 'localhost', '[::1]'].includes(base.hostname), 'Only test a local emulator');
    const request = suffix => fetch(new URL(suffix, base), {redirect: 'manual', signal: AbortSignal.timeout(10000)});
    for (const [document, definition] of Object.entries(LEGAL_DOCUMENTS)) {
      const {route} = definition;
      const bare = await request(route.slice(0, -1));
      assert.equal(bare.status, 301);
      assert.equal(new URL(bare.headers.get('location'), base).pathname, route);
      for (const target of [route, `${route}index.html`]) {
        const response = await request(target);
        assert.equal(response.status, 200, target);
        assert.match(response.headers.get('content-type'), /text\/html/);
        assert.match(response.headers.get('cache-control'), /no-cache/);
        assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
        verifyPage(await response.text(), document, domain);
      }
    }
    for (const target of ['/terminos-de-servicio', '/terminos-de-servicio/']) {
      const response = await request(target);
      assert.equal(response.status, 301);
      assert.equal(new URL(response.headers.get('location'), base).pathname, '/terminos-y-condiciones/');
    }
    // Confirm fallback routing only, not the Flutter runtime in source preview mode.
    const spa = await request('/terms');
    assert.equal(spa.status, 200);
    assert.match(await spa.text(), /flutter_bootstrap/);
  });
}
