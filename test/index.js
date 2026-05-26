const { exec } = require('child_process');
const { test } = require('tapzero');

const packageJson = require('../package.json');

const { devDependencies, version } = packageJson;
const INVALID_TOKEN = 'should error when token is invalid';
const FAKE = 'FAKE';

test('should not have dependencies from now until forever', async (tapzero) => {
  const depKey = 'dependencies';
  const hasDeps = Object.prototype.hasOwnProperty.call(packageJson, depKey);
  tapzero.equal(hasDeps, false);
});

test('should only have 12 devDependency from now until forever', async (tapzero) => {
  const { length } = Object.keys(devDependencies);
  tapzero.equal(length, 12);
});

test('should not error when performing a dry-run publish', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec('./scripts/main.sh', (error) => {
      if (error) {
        reject(new Error(error));
      }
      tapzero.equal(error, null);
      resolve();
    });
  });
});

test('correct version should appear in dry-run output', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec('./scripts/main.sh', (error, stdout) => {
      if (error) {
        reject(new Error(error));
      }
      tapzero.equal(stdout.includes(version), true);
      resolve();
    });
  });
});

test('should error when token is invalid', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec(`YARN_NPM_AUTH_TOKEN=${FAKE} ./scripts/main.sh`, (error) => {
      if (!error) {
        reject(new Error(INVALID_TOKEN));
      }
      tapzero.equal(error.code, 1);
      resolve();
    });
  });
});
