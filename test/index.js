const { exec } = require('child_process');
const { test } = require('tapzero');

const packageJson = require('../package.json');

const { devDependencies, version } = packageJson;
const FAKE = 'FAKE';

test('should not have dependencies from now until forever', async (tapzero) => {
  const depKey = 'dependencies';
  const hasDeps = Object.prototype.hasOwnProperty.call(packageJson, depKey);
  tapzero.equal(hasDeps, false);
});

test('should only have 15 devDependency from now until forever', async (tapzero) => {
  const { length } = Object.keys(devDependencies);
  tapzero.equal(length, 15);
});

test('should not error when performing a dry-run publish', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec('PUBLISH_NPM_TAG=latest ./scripts/main.sh', (error) => {
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
    exec('PUBLISH_NPM_TAG=latest ./scripts/main.sh', {}, (error, stdout) => {
      if (error) {
        reject(new Error(error));
      }
      tapzero.equal(stdout.includes(version), true);
      resolve();
    });
  });
});

test('throws an error when OIDC token is invalid', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec(
      `ACTIONS_ID_TOKEN_REQUEST_URL=${FAKE} ACTIONS_ID_TOKEN_REQUEST_TOKEN=${FAKE} STAGED_PUBLISH=true PUBLISH_NPM_TAG=latest ./scripts/main.sh`,
      (error) => {
        if (!error) {
          reject(new Error('Expected an error but did not get one.'));
        }

        tapzero.equal(error.code, 1);
        resolve();
      },
    );
  });
});
