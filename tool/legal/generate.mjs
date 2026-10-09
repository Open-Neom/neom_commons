#!/usr/bin/env node
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { LEGAL_DOCUMENTS, prepareDocument, writeDocument } from '../privacy/generate.mjs';

// Validate every source before writing any artifact: an invalid or missing terms
// file must not silently leave a deployable, partially updated legal website.
export async function generateLegalPages(options) {
  const documents = await Promise.all(Object.keys(LEGAL_DOCUMENTS).map(document =>
    prepareDocument({ ...options, document })));
  return Promise.all(documents.map(result => writeDocument(result, options)));
}

function parseArgs(args) {
  const options = {};
  const seen = new Set();
  for (let index = 0; index < args.length; index++) {
    const flag = args[index];
    if (seen.has(flag)) throw new Error(`Argumento duplicado: ${flag}.`);
    seen.add(flag);
    if (flag === '--check') options.check = true;
    else if (flag === '--require-published') options.requirePublished = true;
    else if (flag === '--require-approved') options.requireApproved = true;
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
    for (const result of await generateLegalPages(options)) {
      console.log(`${options.check ? 'Verificado' : 'Generado'} (${result.status}): ${result.outputPath}`);
    }
  } catch (error) {
    console.error(`Páginas legales: ${error.message}`);
    process.exitCode = 1;
  }
}
