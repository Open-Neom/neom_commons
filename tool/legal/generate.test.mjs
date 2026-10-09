import assert from 'node:assert/strict';
import {mkdtemp, mkdir, readFile, writeFile, rm, access} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {buildPolicy, LEGAL_DOCUMENTS, prepareDocument} from '../privacy/generate.mjs';
import {generateLegalPages} from './generate.mjs';

const template = await readFile(new URL('../privacy/template.html', import.meta.url), 'utf8');
const command = fileURLToPath(new URL('./generate.mjs', import.meta.url));
const properties = {
  appName: 'App Uno', siteUrl: 'https://old.example',
  privacyPolicyUrl: 'https://uno.example/politica-de-privacidad/',
  termsOfServiceUrl: 'https://old.example/terminos-de-servicio/',
  contactEmail: 'soporte@uno.example', secretKey: 'PRIVATE-CANARY',
};
const metadata = {
  status: 'published', updatedAt: '2026-10-04', controllerName: 'Operador Uno',
  privacyEmail: 'contacto@uno.example', reviewNotes: ['INTERNAL-REVIEW-CANARY'],
};
const markdown = '## Solicitud de {{APP_NAME}}\n\nResponsable: {{CONTROLLER_NAME}}.\n\n'
  + '[Escribir](mailto:{{CONTACT_EMAIL}}?subject=Eliminar%20cuenta)\n\n'
  + '[Privacidad]({{PRIVACY_URL}}), [términos]({{TERMS_URL}}), [eliminación]({{ACCOUNT_DELETION_URL}}).';

async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), 'neom-legal-test-'));
  t.after(() => rm(root, {recursive: true, force: true}));
  await mkdir(path.join(root, 'assets/legal'), {recursive: true});
  await writeFile(path.join(root, 'assets/properties.json'), JSON.stringify(properties));
  await writeFile(path.join(root, 'assets/privacy_policy.json'), JSON.stringify(metadata));
  for (const definition of Object.values(LEGAL_DOCUMENTS)) {
    await writeFile(path.join(root, definition.asset), markdown);
  }
  return root;
}

for (const [document, definition] of Object.entries(LEGAL_DOCUMENTS)) {
  test(`${document}: correct title, canonical, branding and safe cross-links`, () => {
    const {html} = buildPolicy({document, markdown, template, properties, metadata, requirePublished: true});
    assert.ok(html.includes(`<h1>${definition.title}</h1>`));
    assert.ok(html.includes(`rel="canonical" href="https://uno.example${definition.route}"`));
    assert.ok(html.includes('App Uno'));
    assert.ok(html.includes('mailto:contacto@uno.example?subject=Eliminar%20cuenta'));
    for (const target of Object.values(LEGAL_DOCUMENTS)) assert.ok(html.includes(`https://uno.example${target.route}`));
    assert.doesNotMatch(html, /old\.example|PRIVATE-CANARY|INTERNAL-REVIEW-CANARY|\{\{|%%|<script|<form|<iframe|flutter_bootstrap|Borrador/);
  });
}

test('unknown document IDs cannot escape the fixed paths', () => {
  for (const document of ['../private', 'constructor', 'toString']) {
    assert.throws(() => buildPolicy({document, markdown, template, properties, metadata}), /desconocido/);
  }
});

test('valid pending operations are not confused with editorial placeholders', () => {
  for (const body of ['Copias técnicas pendientes de supresión.', 'Pagos pendientes y cualquier acción pendiente.']) {
    assert.doesNotThrow(() => buildPolicy({markdown: body, template, properties, metadata}));
  }
  for (const body of ['Pendiente', '## Pendientes', 'Pendiente de aprobación', 'Por definir', 'TODO']) {
    assert.throws(() => buildPolicy({markdown: body, template, properties, metadata}), /pendientes/);
  }
});

test('the Markdown title does not duplicate the template h1 or appear as literal markup', () => {
  const {html} = buildPolicy({document: 'terms', markdown: '# Términos de {{APP_NAME}}\n\n## Alcance\n\nContenido.\n\n# Otra sección', template, properties, metadata});
  assert.equal((html.match(/<h1>/g) || []).length, 1);
  assert.ok(html.includes('<h2 id="alcance">Alcance</h2>'));
  assert.ok(html.includes('<h2 id="otra-seccion">Otra sección</h2>'));
  assert.doesNotMatch(html, /<p>#/);
});

test('all public documents fail on unrecognized placeholders and unsafe links', () => {
  for (const document of Object.keys(LEGAL_DOCUMENTS)) {
    assert.throws(() => buildPolicy({document, markdown: '{{PRIVATE_KEY}}', template, properties, metadata}), /Placeholder desconocido/);
    assert.throws(() => buildPolicy({document, markdown: '[clic](javascript:alert(1))', template, properties, metadata}), /Protocolo/);
  }
});

test('generates three deterministic artifacts and checks them without rewriting', async t => {
  const root = await fixture(t);
  const options = {appDir: root, requirePublished: true};
  const generated = await generateLegalPages(options);
  assert.equal(generated.length, 3);
  for (const item of generated) assert.equal(await readFile(item.outputPath, 'utf8'), item.html);
  await generateLegalPages({...options, check: true});
  await writeFile(generated[1].outputPath, 'stale deletion page');
  await assert.rejects(generateLegalPages({...options, check: true}), /difiere/);
  assert.equal(await readFile(generated[1].outputPath, 'utf8'), 'stale deletion page');
});

test('validates every source before writing any page', async t => {
  const root = await fixture(t);
  await writeFile(path.join(root, LEGAL_DOCUMENTS.terms.asset), '{{UNKNOWN}}');
  await assert.rejects(generateLegalPages({appDir: root}), /Placeholder desconocido/);
  await assert.rejects(access(path.join(root, 'web')));
});

test('missing terms fail instead of silently publishing only privacy', async t => {
  const root = await fixture(t);
  await rm(path.join(root, LEGAL_DOCUMENTS.terms.asset));
  await assert.rejects(generateLegalPages({appDir: root}), /ENOENT/);
  await assert.rejects(access(path.join(root, 'web')));
});

test('alternate output directory and custom developer branding work', async t => {
  const root = await fixture(t);
  await writeFile(path.join(root, 'assets/properties.json'), JSON.stringify({
    appName: 'Otra & App', siteUrl: 'https://otra.example', contactEmail: 'info@otra.example',
  }));
  await writeFile(path.join(root, 'assets/privacy_policy.json'), JSON.stringify({
    ...metadata, controllerName: 'Otra App', privacyEmail: 'datos@otra.example', themeColor: '#123456',
  }));
  const outputDir = path.join(root, 'build/web');
  const pages = await generateLegalPages({appDir: root, outputDir});
  for (const page of pages) {
    assert.ok(page.outputPath.startsWith(outputDir));
    assert.match(page.html, /Otra &amp; App/);
    assert.match(page.html, /datos@otra\.example/);
    assert.doesNotMatch(page.html, /uno\.example|App Uno/);
  }
});

test('prepare is read-only and CLI rejects invalid options', async t => {
  const root = await fixture(t);
  await prepareDocument({appDir: root, document: 'terms'});
  await assert.rejects(access(path.join(root, 'web')));
  for (const args of [['--app-dir'], ['--bad'], ['--check', '--check']]) {
    const result = spawnSync(process.execPath, [command, ...args], {encoding: 'utf8'});
    assert.notEqual(result.status, 0);
    assert.doesNotMatch(result.stderr, /PRIVATE-CANARY|INTERNAL-REVIEW-CANARY/);
  }
});

test('CLI creates all three pages, checks them and refuses draft publication', async t => {
  const root = await fixture(t);
  const args = [command, '--app-dir', root, '--require-published'];
  let result = spawnSync(process.execPath, args, {encoding: 'utf8'});
  assert.equal(result.status, 0, result.stderr);
  assert.equal((result.stdout.match(/Generado/g) ?? []).length, 3);
  result = spawnSync(process.execPath, [...args, '--check'], {encoding: 'utf8'});
  assert.equal(result.status, 0, result.stderr);
  await writeFile(path.join(root, 'assets/privacy_policy.json'), JSON.stringify({...metadata, status: 'draft'}));
  result = spawnSync(process.execPath, args, {encoding: 'utf8'});
  assert.notEqual(result.status, 0);
});
