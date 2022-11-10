const { exec } = require('child_process');
// eslint-disable-next-line node/no-unpublished-require
const { test } = require('tapzero');
const package = require('../package.json');

const { devDependencies, version } = package;
const INVALID_TOKEN = 'should error when token is invalid';
const FAKE = 'FAKE';

test('should not have dependencies from now until forever', async (t) => {
  const depKey = 'dependencies';
  const hasDeps = Object.prototype.hasOwnProperty.call(package, depKey);
  t.equal(hasDeps, false);
});

test('should only have ten devDependency from now until forever', async (t) => {
  const { length } = Object.keys(devDependencies);
  t.equal(length, 10);
});

test('should not error when performing a dry-run publish', async (t) => {
  await new Promise((resolve, reject) => {
    exec('./scripts/main.sh', (error) => {
      if (error) {
        reject(new Error(error));
      }
      t.equal(error, null);
      resolve();
    });
  });
});

test('correct version should appear in dry-run output', async (t) => {
  await new Promise((resolve, reject) => {
    exec('./scripts/main.sh', (error, stdout) => {
      if (error) {
        reject(new Error(error));
      }
      t.equal(stdout.includes(version), true);
      resolve();
    });
  });
});

test('should error when token is invalid', async (t) => {
  await new Promise((resolve, reject) => {
    exec(`YARN_NPM_AUTH_TOKEN=${FAKE} ./scripts/main.sh`, (error) => {
      if (!error) {
        reject(new Error(INVALID_TOKEN));
      }
      t.equal(error.code, 1);
      resolve();
    });
  });
});
