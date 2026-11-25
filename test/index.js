const { exec } = require('child_process');
const { test } = require('tapzero');

const packageJson = require('../package.json');

const { devDependencies } = packageJson;

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
  await new Promise((resolve, reject) => {
    exec('PUBLISH_NPM_TAG=latest ./scripts/main.sh', (error) => {
      if (!error) {
        reject(new Error('Expected an error but did not get one.'));
      }

      tapzero.equal(error.code, 1);
      resolve();
    });
  });
});

test('throws an error when there is no tarballs directory', async (tapzero) => {
  await new Promise((resolve, reject) => {
    exec('DRY_RUN=true PUBLISH_NPM_TAG=latest ./scripts/main.sh', (error) => {
      if (!error) {
        reject(new Error('Expected an error but did not get one.'));
      }

      tapzero.equal(error.code, 1);
      resolve();
    });
  });
});
