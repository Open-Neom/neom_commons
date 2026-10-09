import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {readFile, stat} from 'node:fs/promises';
import path from 'node:path';
import test from 'node:test';

// Read-only integration checks. No generation, Flutter build or deployment.
// NEOM_LEGAL_APPS_ROOT=/path/to/codebase_flutter node --test tool/legal/hosting.test.mjs
const appsRoot = process.env.NEOM_LEGAL_APPS_ROOT;
const routes = ['/politica-de-privacidad/', '/eliminar-cuenta/', '/terminos-y-condiciones/'];

for (const app of ['Gigmeout', 'Emxi', 'Cyberneom']) {
  for (const configName of ['firebase.json', 'web/firebase.json']) {
    test(`${app}/${configName}: all public legal routes precede the SPA`, {skip: !appsRoot}, async () => {
      const appRoot = path.join(appsRoot, app);
      const configPath = path.join(appRoot, configName);
      const {hosting} = JSON.parse(await readFile(configPath, 'utf8'));
      assert.equal(path.resolve(path.dirname(configPath), hosting.public), path.join(appRoot, 'build/web'));
      assert.equal(Object.hasOwn(hosting, 'trailingSlash'), false, 'Do not alter unrelated SPA paths globally');
      const fallbackIndex = hosting.rewrites.findIndex(rule => rule.source === '**');
      assert.ok(fallbackIndex >= 0, 'Preserve the SPA fallback');
      for (const route of routes) {
        const barePath = route.slice(0, -1);
        const redirects = hosting.redirects.filter(rule => rule.regex === `^${barePath}$`);
        assert.equal(redirects.length, 1, `Expected one exact redirect for ${barePath}`);
        const redirect = redirects[0];
        assert.equal(Object.hasOwn(redirect, 'source'), false, 'Source globs can redirect the canonical slash path to itself');
        assert.equal(redirect.destination, route);
        assert.equal(redirect.type, 301);
        const matcher = new RegExp(redirect.regex);
        assert.ok(matcher.test(barePath));
        assert.ok(!matcher.test(route) && !matcher.test(`${barePath}-other`));
        const rewrites = hosting.rewrites.filter(rule => rule.source === route);
        assert.equal(rewrites.length, 1, `Expected one rewrite for ${route}`);
        assert.equal(rewrites[0].destination, `${route}index.html`);
        assert.ok(hosting.rewrites.indexOf(rewrites[0]) < fallbackIndex);
        const headerRules = hosting.headers.filter(rule => rule.source === `${barePath}{,/**}`);
        assert.equal(headerRules.length, 1, `Expected headers scoped to ${route}`);
        const headers = Object.fromEntries(headerRules[0].headers.map(({key, value}) => [key.toLowerCase(), value]));
        assert.match(headers['cache-control'], /(?:^|,)\s*no-cache(?:,|$)/);
        assert.equal(headers['content-type'], 'text/html; charset=utf-8');
        assert.equal(headers['x-content-type-options'], 'nosniff');
        assert.equal(headers['referrer-policy'], 'no-referrer');
      }
      const legacyRedirects = hosting.redirects.filter(rule => rule.regex === '^/terminos-de-servicio/?$');
      assert.equal(legacyRedirects.length, 1, 'Redirect the legacy terms URL with or without a slash');
      assert.deepEqual(legacyRedirects[0], {
        regex: '^/terminos-de-servicio/?$', destination: '/terminos-y-condiciones/', type: 301,
      });
      const legacyMatcher = new RegExp(legacyRedirects[0].regex);
      for (const legacyPath of ['/terminos-de-servicio', '/terminos-de-servicio/']) {
        assert.ok(legacyMatcher.test(legacyPath));
      }
      for (const unrelatedPath of ['/terms', '/terminos-y-condiciones/', '/terminos-de-servicio/child', '/terminos-de-servicio-other']) {
        assert.ok(!legacyMatcher.test(unrelatedPath));
      }
      for (const redirect of hosting.redirects) {
        for (const flutterRoute of ['/terms', '/terms/']) {
          assert.notEqual(redirect.source, flutterRoute, 'Preserve the Flutter terms route');
          if (redirect.regex) assert.ok(!new RegExp(redirect.regex).test(flutterRoute), 'Preserve the Flutter terms route');
        }
      }
      const legalAssetHeaders = hosting.headers.filter(rule => rule.source === '/assets/assets/legal/{account_deletion,terms_conditions}.md');
      assert.equal(legalAssetHeaders.length, 1, 'Prevent stale bundled legal Markdown');
      const legalHeaders = Object.fromEntries(legalAssetHeaders[0].headers.map(({key, value}) => [key.toLowerCase(), value]));
      assert.equal(legalHeaders['cache-control'], 'no-cache, max-age=0, must-revalidate');
      assert.ok(hosting.ignore.includes('**/privacy_policy.review.json'), 'Keep internal notes excluded');
    });
  }

  test(`${app}: legal assets and deploy script cover all three pages`, {skip: !appsRoot}, async () => {
    const appRoot = path.join(appsRoot, app);
    const pubspec = await readFile(path.join(appRoot, 'pubspec.yaml'), 'utf8');
    assert.equal([...pubspec.matchAll(/^\s*- assets\/legal\/\s*$/gm)].length, 1,
      'Bundle the existing legal directory once, including future account-deletion Markdown');
    assert.ok((await stat(path.join(appRoot, 'assets/legal/terms_conditions.md'))).isFile());
    const scriptPath = path.join(appRoot, 'scripts/deploy_web.sh');
    const script = await readFile(scriptPath, 'utf8');
    assert.match(script, /LEGAL_GENERATOR="\$PROJECT_DIR\/\.\.\/neom_modules\/main\/neom_commons\/tool\/legal\/generate\.mjs"/);
    assert.doesNotMatch(script, /tool\/privacy\/generate\.mjs|PRIVACY_GENERATOR/);
    assert.equal([...script.matchAll(/node "\$LEGAL_GENERATOR"/g)].length, 2,
      'Generate source pages before the build and check copied pages afterward');
    assert.equal([...script.matchAll(/--require-published/g)].length, 2);
    assert.match(script, /--output-dir[^\n]+(?:\\\n\s*)?--check --require-published/);
    execFileSync('bash', ['-n', scriptPath], {stdio: 'pipe'});
  });
}
