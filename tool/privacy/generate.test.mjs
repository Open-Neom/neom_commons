import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, writeFile, rm, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { buildPolicy, generate } from './generate.mjs';

const template = await readFile(new URL('./template.html', import.meta.url), 'utf8');
const command = fileURLToPath(new URL('./generate.mjs', import.meta.url));
const properties = {
  appName: 'Marca Uno', siteUrl: 'https://uno.example/', contactEmail: 'hola@uno.example',
  secretKey: 'PRIVATE-CANARY-DO-NOT-RENDER', unrelatedUrl: 'https://unrelated.example',
};
const metadata = {
  status: 'draft', updatedAt: '2026-10-04', controllerName: '', controllerAddress: '',
  privacyEmail: '', reviewNotes: ['Confirmar la atención de solicitudes.'],
};
const markdown = '## Responsable\n\n**{{APP_NAME}}** — {{CONTROLLER_NAME}}.\n\n[Privacidad]({{PRIVACY_URL}}) y [correo](mailto:{{CONTACT_EMAIL}}).';
const approved = {
  ...metadata, status: 'approved', controllerName: 'Operador Uno',
  controllerAddress: 'Calle Uno 123', privacyEmail: 'privacidad@uno.example', reviewNotes: [],
};
const published = {
  status: 'published', updatedAt: '2026-10-04', controllerName: 'Operador Uno',
  privacyEmail: 'privacidad@uno.example',
};
function build(overrides = {}) {
  return buildPolicy({ markdown, properties, metadata, template, ...overrides });
}

async function fixture(t, options = {}) {
  const directory = await mkdtemp(path.join(tmpdir(), 'privacy-generator-test-'));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const appDir = path.join(directory, 'app');
  await mkdir(path.join(appDir, 'assets'), { recursive: true });
  await Promise.all([
    writeFile(path.join(appDir, 'assets/properties.json'), JSON.stringify(options.properties ?? properties)),
    writeFile(path.join(appDir, 'assets/privacy_policy.json'), JSON.stringify(options.metadata ?? metadata)),
    writeFile(path.join(appDir, 'assets/privacy_policy.md'), options.markdown ?? markdown),
  ]);
  return { directory, appDir };
}

test('draft is visibly marked, noindexed and reports all missing legal fields', () => {
  const result = build();
  assert.match(result.html, /<meta name="robots" content="noindex">/u);
  assert.match(result.html, /Borrador — no publicado/u);
  assert.match(result.html, /Pendiente de confirmar/u);
  assert.deepEqual(result.missingLegalFields, ['controllerName', 'controllerAddress', 'privacyEmail']);
  assert.doesNotMatch(result.html, /Confirmar la atención de solicitudes\./u);
});

test('internal review notes and extra properties never enter HTML, including drafts', () => {
  const reviewCanary = 'INTERNAL-REVIEW-CANARY <private> nunca publicar';
  for (const state of [metadata, published]) {
    const { html } = build({ metadata: { ...state, reviewNotes: [reviewCanary] } });
    assert.doesNotMatch(html, /INTERNAL-REVIEW-CANARY|PRIVATE-CANARY|unrelated\.example|reviewNotes/u);
  }
  assert.doesNotThrow(() => build({ metadata: { ...approved, reviewNotes: undefined } }));
});

test('published requires identity/contact but no physical address or legal approval', () => {
  const { html, status } = build({ metadata: published, requirePublished: true });
  assert.equal(status, 'published');
  assert.match(html, /name="privacy-policy-status" content="published"/u);
  assert.doesNotMatch(html, /name="robots"|<aside\b|Borrador|Pendiente de confirmar|aprobada/u);
  for (const field of ['controllerName', 'privacyEmail']) {
    assert.throws(() => build({ metadata: { ...published, [field]: '' } }), new RegExp(field, 'u'));
  }
  assert.throws(() => build({ metadata: published, requireApproved: true }), /--require-approved/u);
});

test('published requires HTTPS and a body without unresolved placeholders or pending markers', () => {
  assert.throws(() => build({ metadata: published, properties: { ...properties, siteUrl: 'http://uno.example/' } }), /HTTPS/u);
  for (const body of ['{{CONTROLLER_ADDRESS}}', 'Pendiente de confirmar', 'TBD', 'TODO', '{{UNKNOWN}}']) {
    assert.throws(() => build({ metadata: published, markdown: `## Política\n\n${body}` }), /placeholder|pendiente|Placeholder/iu);
  }
  assert.throws(() => build({ metadata: { ...published, controllerName: '{{UNKNOWN}}' } }), /placeholders/u);
});

test('--require-published accepts published/approved and refuses draft', () => {
  for (const state of [published, approved]) assert.doesNotThrow(() => build({ metadata: state, requirePublished: true }));
  assert.throws(() => build({ requirePublished: true }), /--require-published/u);
});

test('unlisted AppProperties never enter the output', () => {
  const { html } = build();
  assert.doesNotMatch(html, /PRIVATE-CANARY|unrelated\.example|secretKey/u);
  assert.doesNotMatch(html, /<script\b|<iframe\b|<link[^>]+(?:stylesheet|fonts)|@import|url\(/iu);
});

test('escapes HTML in Markdown, properties, metadata and link labels', () => {
  const { html } = build({
    properties: { ...properties, appName: '<img src=x onerror="evil()">' },
    metadata: { ...metadata, controllerName: '<script>evil()</script>', reviewNotes: ['<iframe src=x>'] },
    markdown: '## Seguridad\n\n<script>evil()</script> **{{APP_NAME}}** [<img onerror=evil()>](https://example.test/).',
  });
  assert.doesNotMatch(html, /<(?:script|img|iframe)\b/iu);
  assert.match(html, /&lt;script&gt;evil\(\)&lt;\/script&gt;/u);
  assert.match(html, /&lt;img src=x onerror=&quot;evil\(\)&quot;&gt;/u);
});

for (const url of ['javascript:alert(1)', 'data:text/html;base64,SGk=', 'vbscript:msgbox(1)', 'file:///tmp/file', 'jav&#x61;script:evil()', 'https://user:secret@example.test/']) {
  test(`rejects unsafe link protocol or credentials: ${url.split(':')[0]}`, () => {
    assert.throws(() => build({ markdown: `## Enlaces\n\n[Enlace](${url})` }), /enlace|URL/iu);
  });
}

test('unknown placeholders fail in text and links', () => {
  assert.throws(() => build({ markdown: '## {{UNKNOWN}}' }), /Placeholder desconocido/u);
  assert.throws(() => build({ markdown: '[Ayuda]({{SECRET_KEY}})' }), /Placeholder desconocido/u);
  assert.throws(() => build({ markdown: '## {{APP_NAME' }), /Placeholder incompleto/u);
  assert.throws(() => build({ markdown: '## {{APP_{{NAME}}}}' }), /Placeholder incompleto/u);
});

test('replacement is one pass and data cannot inject Markdown markup', () => {
  const { html } = build({
    properties: { ...properties, appName: '{{SITE_URL}} **not bold** [bad](javascript:evil)' },
    markdown: '## Nombre\n\n{{APP_NAME}}\n\n{{SITE_URL}}',
  });
  assert.match(html, /<p>\{\{SITE_URL\}\} \*\*not bold\*\* \[bad\]\(javascript:evil\)<\/p>/u);
  assert.match(html, /<p>https:\/\/uno\.example<\/p>/u);
  assert.doesNotMatch(html, /<strong>not bold|href="javascript:/u);
});

test('uses headings, unique anchors, lists, bold text and safe links', () => {
  const { html } = build({ markdown: [
    '## Qué recopilamos', '', 'Un **dato** con [detalle](https://example.test/a_(b)?x=1&y=2).', '',
    '### Opciones', '', '- Primera', '- Segunda', '', '1. Uno', '2. Dos', '',
    '## Qué recopilamos', '', '[Volver](#que-recopilamos)',
  ].join('\n') });
  assert.match(html, /<h2 id="que-recopilamos">Qué recopilamos<\/h2>/u);
  assert.match(html, /<h2 id="que-recopilamos-2">/u);
  assert.match(html, /<h3 id="opciones">Opciones<\/h3>/u);
  assert.match(html, /<strong>dato<\/strong>/u);
  assert.match(html, /href="https:\/\/example\.test\/a_\(b\)\?x=1&amp;y=2"/u);
  assert.match(html, /<ul>\n  <li>Primera<\/li>\n  <li>Segunda<\/li>\n<\/ul>/u);
  assert.match(html, /<ol>\n  <li>Uno<\/li>\n  <li>Dos<\/li>\n<\/ol>/u);
  assert.match(html, /href="#que-recopilamos-2"/u);
});

test('heading anchors cannot collide with template IDs', () => {
  const { html } = build({ markdown: '## Inicio\n\n## Contenido\n\n## Revision title' });
  assert.match(html, /<h2 id="inicio-2">/u);
  assert.match(html, /<h2 id="contenido-2">/u);
  assert.match(html, /<h2 id="revision-title-2">/u);
  assert.equal((html.match(/id="contenido"/gu) ?? []).length, 1);
});

test('canonical uses validated privacyPolicyUrl and updates SITE_URL consistently', () => {
  const { html } = build({
    properties: { ...properties, siteUrl: 'https://legacy.example/path', privacyPolicyUrl: 'https://dos.example/politica-de-privacidad/' },
    markdown: '## Sitio\n\n{{SITE_URL}}\n\n{{PRIVACY_URL}}',
  });
  assert.match(html, /rel="canonical" href="https:\/\/dos\.example\/politica-de-privacidad\/"/u);
  assert.match(html, /<p>https:\/\/dos\.example<\/p>/u);
  assert.doesNotMatch(html, /legacy\.example/u);
});

test('invalid optional canonical falls back to the site origin and exact policy path', () => {
  for (const privacyPolicyUrl of ['javascript:evil', 'http://other.example/politica-de-privacidad/', 'https://other.example/other/', 'https://other.example/politica-de-privacidad/?token=x']) {
    const { html } = build({ properties: { ...properties, siteUrl: 'https://uno.example/legacy?query=x', privacyPolicyUrl } });
    assert.match(html, /rel="canonical" href="https:\/\/uno\.example\/politica-de-privacidad\/"/u);
    assert.doesNotMatch(html, /other\.example|token=x|query=x/u);
  }
});

test('uses the privacy mailbox consistently, with contactEmail as draft fallback', () => {
  const { html } = build({ metadata: approved });
  assert.match(html, /href="mailto:privacidad@uno\.example"/u);
  assert.doesNotMatch(html, /hola@uno\.example/u);
  assert.match(build().html, /href="mailto:hola@uno\.example"/u);
});

test('draft cannot pass the approval gate even when legal metadata is complete', () => {
  assert.throws(() => build({ requireApproved: true, metadata: { ...approved, status: 'draft' } }), /--require-approved/u);
});

test('approved status rejects empty legal metadata even without the gate', () => {
  for (const field of ['controllerName', 'controllerAddress', 'privacyEmail']) {
    assert.throws(() => build({ metadata: { ...approved, [field]: '' } }), new RegExp(field, 'u'));
  }
});

test('approval gate rejects review notes and unresolved content', () => {
  assert.throws(() => build({ requireApproved: true, metadata: { ...approved, reviewNotes: ['Revisar conservación.'] } }), /--require-approved/u);
  for (const marker of ['Pendiente de confirmar', 'TBD', 'Por definir', 'TODO']) {
    assert.throws(() => build({ requireApproved: true, metadata: approved, markdown: `## Retención\n\n${marker}` }), /--require-approved/u);
  }
});

test('approved status rejects unresolved content even without --require-approved', () => {
  assert.throws(() => build({ metadata: { ...approved, reviewNotes: ['Confirmar revisión.'] } }), /reviewNotes/u);
  assert.throws(() => build({ metadata: approved, markdown: '## Retención\n\nPendiente de confirmar.' }), /marcador pendiente/u);
});

test('ordinary Spanish todo does not count as an unresolved TODO marker', () => {
  assert.doesNotThrow(() => build({ requireApproved: true, metadata: approved, markdown: '## Alcance\n\nTodo el contenido se trata según esta política. Revisa todo el texto.' }));
});

test('--require-approved requires HTTPS for the canonical domain', () => {
  assert.throws(() => build({ requireApproved: true, metadata: approved, properties: { ...properties, siteUrl: 'http://uno.example' } }), /HTTPS/u);
});

test('approved, complete policy passes the gate and has no draft banner or noindex', () => {
  const { html } = build({ requireApproved: true, metadata: approved });
  assert.match(html, /name="privacy-policy-status" content="approved"/u);
  assert.doesNotMatch(html, /name="robots"|Borrador pendiente|Pendiente de confirmar/u);
});

test('validates dates, themes, emails and required shapes without leaking values', () => {
  for (const invalid of [{ updatedAt: '2026-02-30' }, { themeColor: '#fff; background:red' }, { privacyEmail: '<script>alert(1)</script>' }, { reviewNotes: 'not a list' }, { status: 'unknown' }]) {
    assert.throws(() => build({ metadata: { ...metadata, ...invalid } }));
  }
  assert.match(build({ metadata: { ...metadata, themeColor: '#753f27' } }).html, /--brand: #753f27/u);
});

test('two app fixtures remain isolated and generation is deterministic', async t => {
  const first = await fixture(t);
  const second = await fixture(t, { properties: { appName: 'Marca Dos', siteUrl: 'https://dos.example', contactEmail: 'hola@dos.example' } });
  const a = await generate({ appDir: first.appDir });
  const b = await generate({ appDir: second.appDir });
  assert.match(a.html, /Marca Uno/u);
  assert.doesNotMatch(a.html, /Marca Dos|dos\.example/u);
  assert.match(b.html, /Marca Dos/u);
  assert.doesNotMatch(b.html, /Marca Uno|uno\.example/u);
  assert.equal((await generate({ appDir: first.appDir, check: true })).html, a.html);
  assert.equal(a.outputPath, path.join(first.appDir, 'web/politica-de-privacidad/index.html'));
});

test('--check compares exact content without writing, and alternate web roots work', async t => {
  const { appDir, directory } = await fixture(t);
  const outputDir = path.join(directory, 'build/web');
  await assert.rejects(generate({ appDir, outputDir, check: true }), /Falta el artefacto/u);
  const { outputPath, html } = await generate({ appDir, outputDir });
  const originalStat = await stat(outputPath);
  await generate({ appDir, outputDir, check: true });
  assert.equal((await stat(outputPath)).mtimeMs, originalStat.mtimeMs);
  await writeFile(outputPath, `${html}\n`);
  await assert.rejects(generate({ appDir, outputDir, check: true }), /difiere/u);
  assert.equal(await readFile(outputPath, 'utf8'), `${html}\n`);
});

test('CLI reports missing field names without properties secrets and refuses gated writes', async t => {
  const { appDir, directory } = await fixture(t);
  const result = spawnSync(process.execPath, [command, '--app-dir', appDir], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /controllerName, controllerAddress, privacyEmail/u);
  assert.doesNotMatch(result.stdout + result.stderr, /PRIVATE-CANARY/u);
  const outputDir = path.join(directory, 'blocked-output');
  const blocked = spawnSync(process.execPath, [command, '--app-dir', appDir, '--output-dir', outputDir, '--require-approved'], { encoding: 'utf8' });
  assert.equal(blocked.status, 1);
  await assert.rejects(stat(outputDir), { code: 'ENOENT' });
});

test('CLI publication gate supports metadata without reviewNotes/address and retains the approval gate', async t => {
  const { appDir } = await fixture(t, { metadata: published });
  const result = spawnSync(process.execPath, [command, '--app-dir', appDir, '--require-published'], { encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr);
  const check = spawnSync(process.execPath, [command, '--app-dir', appDir, '--check', '--require-published'], { encoding: 'utf8' });
  assert.equal(check.status, 0, check.stderr);
  const refused = spawnSync(process.execPath, [command, '--app-dir', appDir, '--check', '--require-approved'], { encoding: 'utf8' });
  assert.equal(refused.status, 1);
  assert.match(refused.stderr, /--require-approved/u);
});
