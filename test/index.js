const { execFile } = require('child_process');
const { createHash } = require('crypto');
const { mkdir, mkdtemp, readFile, writeFile } = require('fs/promises');
const os = require('os');
const path = require('path');
const { test } = require('tapzero');
const { promisify } = require('util');

const packageJson = require('../package.json');

const { devDependencies } = packageJson;

const execFileAsync = promisify(execFile);
const SCRIPTS = path.resolve(__dirname, '../scripts');

/**
 * Run a script from the `scripts` directory, whether it fails or not.
 *
 * @param {string} script - The file name of the script.
 * @param {Record<string, string>} env - The environment variables to set, in
 * addition to the ones of this process (the scripts need `PATH`).
 * @param {string} [binDirectory] - A directory to put at the start of `PATH`,
 * e.g., with a fake `npm`.
 * @returns {Promise<{ code: number, stdout: string }>} The exit code and the
 * standard output of the script.
 */
async function run(script, env = {}, binDirectory = undefined) {
  /* eslint-disable n/no-process-env */
  const pathValue = binDirectory
    ? `${binDirectory}${path.delimiter}${process.env.PATH}`
    : process.env.PATH;

  try {
    const { stdout } = await execFileAsync(path.join(SCRIPTS, script), [], {
      env: { ...process.env, PATH: pathValue, ...env },
    });
    return { code: 0, stdout };
  } catch (error) {
    return { code: error.code, stdout: error.stdout };
  }
  /* eslint-enable n/no-process-env */
}

/**
 * Create a directory with a fake `npm`, which the scripts use to look up what
 * is published. The fake only handles `npm view <spec>`.
 *
 * @param {boolean} published - Whether the package has been published before,
 * in version `0.9.0`. If it's not, `npm view` fails for every spec.
 * @returns {Promise<string>} The path of the directory.
 */
async function createFakeNpm(published) {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'bin-'));
  const body = published
    ? 'case "$2" in\n  *@*) exit 1 ;;\n  *) echo \'{"version":"0.9.0"}\' ;;\nesac'
    : 'exit 1';

  await writeFile(path.join(directory, 'npm'), `#!/bin/sh\n${body}\n`, {
    mode: 0o755,
  });
  return directory;
}

/**
 * Create a new, empty directory for tarballs.
 *
 * @returns {Promise<string>} The path of the directory.
 */
async function createDirectory() {
  return await mkdtemp(path.join(os.tmpdir(), 'tarballs-'));
}

/**
 * Create a tarball in the same layout as `yarn pack`.
 *
 * @param {string} directory - The directory to create the tarball in.
 * @param {{ name: string, version: string }} manifest - The contents of the
 * `package.json` in the tarball.
 * @returns {Promise<string>} The path of the tarball.
 */
async function createTarball(directory, manifest) {
  const work = await mkdtemp(path.join(os.tmpdir(), 'work-'));
  await mkdir(path.join(work, 'package'));
  await writeFile(
    path.join(work, 'package', 'package.json'),
    JSON.stringify(manifest),
  );

  const file = path.join(directory, `${manifest.name.replace('/', '-')}.tgz`);
  await execFileAsync('tar', ['-czf', file, '-C', work, 'package']);
  return file;
}

/**
 * Get the integrity of a file, as in the npm registry.
 *
 * @param {string} file - The path of the file.
 * @returns {Promise<string>} The SHA-512 of the file, as `sha512-<base64>`.
 */
async function integrity(file) {
  const hash = createHash('sha512').update(await readFile(file));
  return `sha512-${hash.digest('base64')}`;
}

/**
 * Run `list-tarballs.sh`, whether it fails or not.
 *
 * @param {string} directory - The directory with the tarballs.
 * @returns {Promise<{ code: number, stdout: string }>} The exit code and the
 * standard output of the script.
 */
async function listTarballs(directory) {
  try {
    const { stdout } = await execFileAsync(
      path.join(SCRIPTS, 'list-tarballs.sh'),
      [directory],
    );
    return { code: 0, stdout };
  } catch (error) {
    return { code: error.code, stdout: error.stdout };
  }
}

test('should not have dependencies from now until forever', async (tapzero) => {
  const depKey = 'dependencies';
  const hasDeps = Object.prototype.hasOwnProperty.call(packageJson, depKey);
  tapzero.equal(hasDeps, false);
});

test('should only have 15 devDependency from now until forever', async (tapzero) => {
  const { length } = Object.keys(devDependencies);
  tapzero.equal(length, 15);
});

test('throws an error when dry-run is not set', async (tapzero) => {
  const { code } = await run('main.sh', { PUBLISH_NPM_TAG: 'latest' });
  tapzero.equal(code, 1);
});

test('throws an error when there is no tarballs directory', async (tapzero) => {
  const { code } = await run('main.sh', {
    DRY_RUN: 'true',
    PUBLISH_NPM_TAG: 'latest',
  });
  tapzero.equal(code, 1);
});

test('lists the tarballs with their integrity, sorted', async (tapzero) => {
  const directory = await createDirectory();
  const b = await createTarball(directory, { name: 'b', version: '1.0.0' });
  const a = await createTarball(directory, {
    name: '@scope/a',
    version: '2.0.0-beta.1',
  });

  const { code, stdout } = await listTarballs(directory);

  tapzero.equal(code, 0);
  tapzero.equal(
    stdout,
    `@scope/a@2.0.0-beta.1 ${await integrity(a)}\nb@1.0.0 ${await integrity(b)}\n`,
  );
});

test('does not list a tarball with a name that is not allowed', async (tapzero) => {
  const directory = await createDirectory();
  await createTarball(directory, { name: 'a\n::error::x', version: '1.0.0' });

  const { code } = await listTarballs(directory);

  tapzero.equal(code, 1);
});

test('requires the checksums to publish', async (tapzero) => {
  const directory = await createDirectory();
  await createTarball(directory, { name: 'a', version: '1.0.0' });

  const { code, stdout } = await run('publish.sh', {
    TARBALLS_DIRECTORY: directory,
    DRY_RUN: 'false',
    PUBLISH_NPM_TAG: 'latest',
  });

  tapzero.equal(code, 1);
  tapzero.equal(stdout.includes("'checksums' is required"), true);
});

test('does not publish tarballs that differ from the checksums', async (tapzero) => {
  const directory = await createDirectory();
  await createTarball(directory, { name: 'a', version: '1.0.0' });

  // The checksums are for a tarball with other contents.
  const other = await createTarball(await createDirectory(), {
    name: 'a',
    version: '1.0.0',
    scripts: { postinstall: 'echo hi' },
  });

  const { code, stdout } = await run('publish.sh', {
    TARBALLS_DIRECTORY: directory,
    CHECKSUMS: `a@1.0.0 ${await integrity(other)}`,
    DRY_RUN: 'true',
    PUBLISH_NPM_TAG: 'latest',
  });

  tapzero.equal(code, 1);
  tapzero.equal(
    stdout.includes('not the tarballs that were packed in the dry run'),
    true,
  );
});

test('warns about new packages at the top of the job summary', async (tapzero) => {
  const directory = await createDirectory();
  await createTarball(directory, { name: 'new-package', version: '1.0.0' });
  const summary = path.join(await createDirectory(), 'summary.md');

  const { code, stdout } = await run(
    'publish.sh',
    {
      TARBALLS_DIRECTORY: directory,
      GITHUB_STEP_SUMMARY: summary,
      DRY_RUN: 'true',
      PUBLISH_NPM_TAG: 'latest',
    },
    await createFakeNpm(false),
  );

  const contents = await readFile(summary, 'utf8');

  tapzero.equal(code, 0);
  tapzero.equal(contents.startsWith('> [!WARNING]\n'), true);
  tapzero.equal(contents.includes('> - `new-package@1.0.0`'), true);
  tapzero.equal(contents.indexOf('## Release details') > 0, true);
  tapzero.equal(stdout.includes('::warning::'), true);
});

test('does not warn about packages that have been published before', async (tapzero) => {
  const directory = await createDirectory();
  await createTarball(directory, { name: 'old-package', version: '1.0.0' });
  const summary = path.join(await createDirectory(), 'summary.md');

  const { code, stdout } = await run(
    'publish.sh',
    {
      TARBALLS_DIRECTORY: directory,
      GITHUB_STEP_SUMMARY: summary,
      DRY_RUN: 'true',
      PUBLISH_NPM_TAG: 'latest',
    },
    await createFakeNpm(true),
  );

  const contents = await readFile(summary, 'utf8');

  tapzero.equal(code, 0);
  tapzero.equal(contents.startsWith('## Release details'), true);
  tapzero.equal(contents.includes('[!WARNING]'), false);
  tapzero.equal(stdout.includes('::warning::'), false);
});
