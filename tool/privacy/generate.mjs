#!/usr/bin/env node
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const POLICY_PATH = '/politica-de-privacidad/';
// Fixed, developer-owned routes and assets. Never accept a path from public metadata.
export const LEGAL_DOCUMENTS = Object.freeze({
  privacy: Object.freeze({
    route: POLICY_PATH, asset: 'assets/privacy_policy.md',
    title: 'Política de privacidad',
    intro: 'Información sobre los datos personales en {{APP_NAME}} y cómo presentar solicitudes sobre ellos.',
  }),
  accountDeletion: Object.freeze({
    route: '/eliminar-cuenta/', asset: 'assets/legal/account_deletion.md',
    title: 'Eliminar cuenta y datos',
    intro: 'Cómo solicitar la eliminación de tu cuenta y tus datos en {{APP_NAME}}, incluso sin iniciar sesión ni tener instalada la aplicación.',
  }),
  terms: Object.freeze({
    route: '/terminos-y-condiciones/', asset: 'assets/legal/terms_conditions.md',
    title: 'Términos y condiciones',
    intro: 'Condiciones de uso, contenido y convivencia en {{APP_NAME}}.',
  }),
});

function documentDefinition(document) {
  if (!Object.hasOwn(LEGAL_DOCUMENTS, document)) throw new Error(`Documento legal desconocido: ${document}.`);
  return LEGAL_DOCUMENTS[document];
}
const PENDING = 'Pendiente de confirmar';
// Reject editorial placeholders, not valid disclosures such as "pagos pendientes"
// or "copias pendientes de supresión".
const PENDING_PATTERN = /\b(?:pendiente(?:s)? de (?:confirmar|confirmación|definir|definición|aprobar|aprobación|revisar|revisión|validar|validación)|por confirmar|por definir|tbd)\b/iu;
const hasPendingMarker = text => PENDING_PATTERN.test(text) || /\bTODO\b/u.test(text)
  || /^\s*(?:[#*>-]+\s*)?pendiente(?:s)?[.!:]?\s*$/imu.test(text);
const templatePath = fileURLToPath(new URL('./template.html', import.meta.url));

export function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, character => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[character]);
}

function stringField(value, name, { optional = false } = {}) {
  if (optional && (value == null || value === '')) return '';
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`Falta el campo de texto ${name}.`);
  }
  if (/[\u0000-\u001f\u007f]/u.test(value)) {
    throw new Error(`El campo ${name} contiene caracteres de control.`);
  }
  return value.trim();
}

function emailField(value, name, options) {
  const email = stringField(value, name, options);
  if (email && !/^[^\s<>"'@]+@[^\s<>"'@]+\.[^\s<>"'@]+$/u.test(email)) {
    throw new Error(`El campo ${name} no es un correo válido.`);
  }
  return email;
}

function canonicalUrl(privacyPolicyUrl, siteUrl) {
  // A valid app-specific canonical has precedence over legacy site branding.
  if (typeof privacyPolicyUrl === 'string') {
    try {
      const candidate = new URL(privacyPolicyUrl);
      if (candidate.protocol === 'https:' && candidate.pathname === POLICY_PATH
          && !candidate.username && !candidate.password
          && !candidate.search && !candidate.hash) return candidate.href;
    } catch { /* Invalid optional canonical: validate and use siteUrl below. */ }
  }
  let site;
  try { site = new URL(stringField(siteUrl, 'siteUrl')); }
  catch { throw new Error('siteUrl debe ser una URL HTTP(S) absoluta válida.'); }
  if (!['https:', 'http:'].includes(site.protocol) || site.username || site.password) {
    throw new Error('siteUrl debe ser una URL HTTP(S) absoluta sin credenciales.');
  }
  return `${site.origin}${POLICY_PATH}`;
}

function validateDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/u.test(value)) {
    throw new Error('updatedAt debe usar el formato YYYY-MM-DD.');
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  if (!Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw new Error('updatedAt no es una fecha válida.');
  }
  return value;
}

function substituteOnce(text, values) {
  const withoutTokens = text.replace(/\{\{[^{}]*\}\}/gu, '');
  if (withoutTokens.includes('{{') || withoutTokens.includes('}}')) {
    throw new Error('Placeholder incompleto o anidado en la fuente Markdown.');
  }
  return text.replace(/\{\{([^{}]*)\}\}/gu, (_, key) => {
    if (!Object.hasOwn(values, key)) throw new Error(`Placeholder desconocido: {{${key}}}.`);
    return values[key];
  });
}

function safeLink(rawUrl, values) {
  const url = substituteOnce(rawUrl, values).trim();
  if (/[\u0000-\u0020\u007f<>"']/u.test(url)) {
    throw new Error('Un enlace contiene espacios o caracteres no permitidos.');
  }
  if (/^#[\p{L}\p{N}_-]+$/u.test(url)) return url;
  let parsed;
  try { parsed = new URL(url); }
  catch { throw new Error('Los enlaces deben usar una URL HTTP(S), mailto o un ancla válida.'); }
  if (!['https:', 'http:', 'mailto:'].includes(parsed.protocol)
      || parsed.username || parsed.password) {
    throw new Error('Protocolo de enlace no permitido; usa HTTP(S), mailto o un ancla.');
  }
  return url;
}

function linkEnd(text, start) {
  let depth = 1;
  for (let i = start; i < text.length; i++) {
    if (text[i] === '(') depth++;
    if (text[i] === ')' && --depth === 0) return i;
  }
  return -1;
}

function inline(text, values, allowLinks = true) {
  let output = '';
  for (let index = 0; index < text.length;) {
    const tail = text.slice(index);
    const placeholder = /^\{\{([^{}]*)\}\}/u.exec(tail);
    if (placeholder) {
      output += escapeHtml(substituteOnce(placeholder[0], values));
      index += placeholder[0].length;
      continue;
    }
    if (tail.startsWith('**')) {
      const end = text.indexOf('**', index + 2);
      if (end > index + 2) {
        output += `<strong>${inline(text.slice(index + 2, end), values, allowLinks)}</strong>`;
        index = end + 2;
        continue;
      }
    }
    if (allowLinks && tail.startsWith('[')) {
      const labelEnd = text.indexOf('](', index + 1);
      const end = labelEnd < 0 ? -1 : linkEnd(text, labelEnd + 2);
      if (end >= 0) {
        const href = safeLink(text.slice(labelEnd + 2, end), values);
        output += `<a href="${escapeHtml(href)}">${inline(text.slice(index + 1, labelEnd), values, false)}</a>`;
        index = end + 1;
        continue;
      }
    }
    output += escapeHtml(text[index++]);
  }
  return output;
}

export function renderMarkdown(markdown, values) {
  if (typeof markdown !== 'string' || !markdown.trim()) throw new Error('La política Markdown está vacía.');
  substituteOnce(markdown, values); // Validate every source placeholder, including URLs.
  const blocks = [];
  const headings = [];
  const usedIds = new Set(['inicio', 'contenido', 'revision-title']);
  let paragraph = [];
  let list = null;
  let sourceTitleHandled = false;
  const flushParagraph = () => {
    if (paragraph.length) blocks.push(`<p>${inline(paragraph.join(' '), values)}</p>`);
    paragraph = [];
  };
  const flushList = () => {
    if (list) blocks.push(`<${list.type}>\n${list.items.map(item => `  <li>${inline(item, values)}</li>`).join('\n')}\n</${list.type}>`);
    list = null;
  };
  for (const line of markdown.replace(/\r\n?/gu, '\n').split('\n')) {
    const heading = /^(#{1,3})\s+(.+)$/u.exec(line);
    const item = /^\s*(?:([-+*])|\d+\.)\s+(.+)$/u.exec(line);
    if (!line.trim()) { flushParagraph(); flushList(); continue; }
    if (heading) {
      // The shared HTML shell already supplies the single page-level h1.
      // Markdown keeps its title for readers and the in-app asset renderer.
      if (heading[1] === '#' && !sourceTitleHandled && !blocks.length
          && !paragraph.length && !list) {
        sourceTitleHandled = true;
        continue;
      }
      flushParagraph(); flushList();
      const label = substituteOnce(heading[2], values).replace(/\*\*/gu, '');
      const base = label.normalize('NFKD').replace(/[\u0300-\u036f]/gu, '').toLowerCase()
        .replace(/[^a-z0-9]+/gu, '-').replace(/^-|-$/gu, '') || 'seccion';
      let id = base;
      for (let suffix = 2; usedIds.has(id); suffix++) id = `${base}-${suffix}`;
      usedIds.add(id);
      const level = Math.max(2, heading[1].length);
      blocks.push(`<h${level} id="${id}">${inline(heading[2], values)}</h${level}>`);
      if (level === 2) headings.push({ id, label });
    } else if (item) {
      flushParagraph();
      const type = item[1] ? 'ul' : 'ol';
      if (list?.type !== type) { flushList(); list = { type, items: [] }; }
      list.items.push(item[2]);
    } else {
      flushList(); paragraph.push(line.trim());
    }
  }
  flushParagraph(); flushList();
  return {
    content: blocks.join('\n'),
    toc: headings.map(({ id, label }) => `<li><a href="#${id}">${escapeHtml(label)}</a></li>`).join('\n'),
  };
}

export function buildPolicy({ markdown, properties, metadata, template, requireApproved = false, requirePublished = false, document = 'privacy' }) {
  const definition = documentDefinition(document);
  if (!properties || typeof properties !== 'object' || Array.isArray(properties)) throw new Error('properties.json debe ser un objeto.');
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) throw new Error('privacy_policy.json debe ser un objeto.');
  // This is the complete properties whitelist. Never serialize or spread AppProperties.
  const { appName, siteUrl, contactEmail, privacyPolicyUrl } = properties;
  const name = stringField(appName, 'appName');
  const privacyCanonical = canonicalUrl(privacyPolicyUrl, siteUrl);
  const site = new URL(privacyCanonical).origin;
  const canonical = `${site}${definition.route}`;
  const contact = emailField(contactEmail, 'contactEmail');
  const privacyEmail = emailField(metadata.privacyEmail, 'privacyEmail', { optional: true });
  const controllerName = stringField(metadata.controllerName, 'controllerName', { optional: true });
  const controllerAddress = stringField(metadata.controllerAddress, 'controllerAddress', { optional: true });
  const status = metadata.status;
  if (!['draft', 'published', 'approved'].includes(status)) throw new Error('status debe ser draft, published o approved.');
  const updatedAt = validateDate(metadata.updatedAt);
  const themeColor = metadata.themeColor ?? '#111c41';
  if (typeof themeColor !== 'string' || !/^#[a-f\d]{6}$/iu.test(themeColor)) throw new Error('themeColor debe ser un color hexadecimal de seis dígitos.');
  // Legacy input only. Internal review notes must never enter template slots.
  const reviewNotes = metadata.reviewNotes === undefined ? [] : metadata.reviewNotes;
  if (!Array.isArray(reviewNotes) || reviewNotes.some(note => typeof note !== 'string' || !note.trim())) {
    throw new Error('reviewNotes debe ser una lista de textos no vacíos.');
  }
  const missingLegalFields = Object.entries({ controllerName, controllerAddress, privacyEmail })
    .filter(([, value]) => !value).map(([key]) => key);
  if (status === 'approved' && missingLegalFields.length) {
    throw new Error(`Una política aprobada requiere: ${missingLegalFields.join(', ')}.`);
  }
  if (status === 'published' && (!controllerName || !privacyEmail)) {
    throw new Error('Una política published requiere controllerName y privacyEmail.');
  }
  const values = {
    APP_NAME: name, SITE_URL: site, PRIVACY_URL: privacyCanonical,
    TERMS_URL: `${site}${LEGAL_DOCUMENTS.terms.route}`,
    ACCOUNT_DELETION_URL: `${site}${LEGAL_DOCUMENTS.accountDeletion.route}`,
    CONTACT_EMAIL: privacyEmail || contact,
    CONTROLLER_NAME: controllerName || PENDING,
    CONTROLLER_ADDRESS: controllerAddress || PENDING, UPDATED_AT: updatedAt,
  };
  const expanded = substituteOnce(markdown, values);
  if (requireApproved && status !== 'approved') {
    throw new Error('--require-approved requiere status approved.');
  }
  if (requirePublished && !['published', 'approved'].includes(status)) {
    throw new Error('--require-published requiere status published o approved.');
  }
  if (status === 'approved' && (reviewNotes.length || hasPendingMarker(expanded)
      || [controllerName, controllerAddress, privacyEmail].some(hasPendingMarker))) {
    throw new Error('Una política approved, incluida --require-approved, requiere reviewNotes vacías y ningún marcador pendiente.');
  }
  if ((status === 'published' || requirePublished || requireApproved) && new URL(canonical).protocol !== 'https:') {
    throw new Error('La publicación y --require-approved requieren un dominio canónico HTTPS.');
  }
  if (status !== 'draft' && (hasPendingMarker(expanded) || /\{\{|\}\}/u.test(expanded)
      || [name, controllerName, privacyEmail].some(value => hasPendingMarker(value) || /\{\{|\}\}/u.test(value)))) {
    throw new Error('La política pública no puede contener placeholders ni marcadores pendientes.');
  }
  const { content, toc } = renderMarkdown(markdown, values);
  const draftNotice = status === 'draft'
    ? '<aside class="review" aria-labelledby="revision-title"><strong id="revision-title">Borrador — no publicado</strong><p>Este documento todavía no está marcado para su publicación.</p></aside>'
    : '';
  const slots = {
    APP_NAME: escapeHtml(name), SITE_URL: escapeHtml(site), PRIVACY_URL: escapeHtml(privacyCanonical),
    PAGE_TITLE: escapeHtml(definition.title), PAGE_URL: escapeHtml(canonical),
    PAGE_INTRO: escapeHtml(substituteOnce(definition.intro, values)),
    TERMS_URL: escapeHtml(values.TERMS_URL), ACCOUNT_DELETION_URL: escapeHtml(values.ACCOUNT_DELETION_URL),
    STATUS_META_NAME: document === 'privacy' ? 'privacy-policy-status' : 'legal-document-status',
    STATUS: status, UPDATED_AT: updatedAt, THEME_COLOR: themeColor,
    ROBOTS: status === 'draft' ? '<meta name="robots" content="noindex">' : '',
    DRAFT_NOTICE: draftNotice, CONTENT: content, TOC: toc,
    CONTACT_EMAIL: escapeHtml(values.CONTACT_EMAIL),
  };
  const html = template.replace(/%%([A-Z_]+)%%/gu, (_, key) => {
    if (!Object.hasOwn(slots, key)) throw new Error(`Slot desconocido en template.html: ${key}.`);
    return slots[key];
  });
  return { html, missingLegalFields, status };
}

export async function prepareDocument({ appDir, outputDir, requireApproved = false, requirePublished = false, document = 'privacy' }) {
  if (!appDir) throw new Error('Debes indicar --app-dir <directorio>.');
  const definition = documentDefinition(document);
  const root = path.resolve(appDir);
  const [markdown, propertiesText, metadataText, template] = await Promise.all([
    readFile(path.join(root, definition.asset), 'utf8'),
    readFile(path.join(root, 'assets/properties.json'), 'utf8'),
    readFile(path.join(root, 'assets/privacy_policy.json'), 'utf8'),
    readFile(templatePath, 'utf8'),
  ]);
  let properties;
  let metadata;
  try { properties = JSON.parse(propertiesText); } catch { throw new Error('properties.json no contiene JSON válido.'); }
  try { metadata = JSON.parse(metadataText); } catch { throw new Error('privacy_policy.json no contiene JSON válido.'); }
  const result = buildPolicy({ markdown, properties, metadata, template, requireApproved, requirePublished, document });
  const outputPath = path.join(outputDir ? path.resolve(outputDir) : path.join(root, 'web'), definition.route.slice(1), 'index.html');
  return { ...result, outputPath, document };
}

export async function writeDocument(result, { check = false } = {}) {
  const { outputPath } = result;
  if (check) {
    let current;
    try { current = await readFile(outputPath, 'utf8'); }
    catch (error) {
      if (error.code === 'ENOENT') throw new Error(`Falta el artefacto de privacidad/documento legal ${result.document}; ejecútalo sin --check para generarlo.`);
      throw error;
    }
    if (current !== result.html) throw new Error(`La página de privacidad/documento legal ${result.document} difiere de sus fuentes; vuelve a generarla.`);
  } else {
    await mkdir(path.dirname(outputPath), { recursive: true });
    await writeFile(outputPath, result.html, 'utf8');
  }
  return { ...result, outputPath };
}

// Backwards-compatible single-policy entrypoint. The legal CLI builds all three.
export async function generate(options) {
  return writeDocument(await prepareDocument(options), options);
}

function parseArgs(args) {
  const options = {};
  const seen = new Set();
  for (let index = 0; index < args.length; index++) {
    const flag = args[index];
    if (seen.has(flag)) throw new Error(`Argumento duplicado: ${flag}.`);
    seen.add(flag);
    if (flag === '--check') options.check = true;
    else if (flag === '--require-approved') options.requireApproved = true;
    else if (flag === '--require-published') options.requirePublished = true;
    else if (flag === '--app-dir' || flag === '--output-dir') {
      const value = args[++index];
      if (!value || value.startsWith('--')) throw new Error(`Falta el valor de ${flag}.`);
      options[flag === '--app-dir' ? 'appDir' : 'outputDir'] = value;
    } else throw new Error(`Argumento desconocido: ${flag}.`);
  }
  return options;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  try {
    const options = parseArgs(process.argv.slice(2));
    const result = await generate(options);
    console.log(`${options.check ? 'Verificado' : 'Generado'} (${result.status}): ${result.outputPath}`);
    console.log(`Datos legales faltantes: ${result.missingLegalFields.join(', ') || 'ninguno'}.`);
  } catch (error) {
    console.error(`Privacidad: ${error.message}`);
    process.exitCode = 1;
  }
}
