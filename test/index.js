const { exec } = require('child_process');
const { test } = require('tapzero');
const package = require('../package.json');

const { devDependencies, version } = package;

test('should not have dependencies from now until forever', async t => {
  const depKey = 'dependencies'
  const hasDeps = Object.prototype.hasOwnProperty.call(package, depKey);
  t.equal(hasDeps, false);
});

test('should only have one devDependency from now until forever', async t => {
  const { length } = Object.keys(devDependencies)
  t.equal(length, 1);
});

test('should not error when performing a dry-run publish', async t => {
  await new Promise(resolve => {
    exec("./scripts/publish.sh", error => {
      t.equal(error, null);
      resolve();
    });
  });
});

test('correct version should appear in dry-run output', async t => {
  await new Promise(resolve => {
    exec("./scripts/publish.sh", (_, __, stderr) => {
      const { version } = package;
      const re = new RegExp(`${version}`, 'g');
      t.equal(stderr.match(re).length, 2);
      resolve();
    });
  });
});

test('should error when token is invalid', async t => {
  await new Promise(resolve => {
    exec("NPM_TOKEN=womp ./scripts/publish.sh", error => {
      t.equal(error.code, 1);
      resolve();
    });
  });
});
