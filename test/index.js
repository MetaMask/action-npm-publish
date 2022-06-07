const { exec } = require('child_process');
const { test } = require('tapzero');
const package = require('../package.json');

const { devDependencies, version } = package;
const FAKE = 'FAKE';

test('should not have dependencies from now until forever', async t => {
  const depKey = 'dependencies';
  const hasDeps = Object.prototype.hasOwnProperty.call(package, depKey);
  t.equal(hasDeps, false);
});

test('should only have one devDependency from now until forever', async t => {
  const { length } = Object.keys(devDependencies);
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
      t.equal(stderr.includes(version), true);
      resolve();
    });
  });
});

test('should error when token is invalid', async t => {
  await new Promise(resolve => {
    exec(`NPM_TOKEN=${FAKE} ./scripts/publish.sh`, error => {
      t.equal(error.code, 1);
      resolve();
    });
  });
});

test('should correctly set NPM token', async t => {
  await new Promise(resolve => {
    exec(`NPM_TOKEN=${FAKE} ./scripts/config_set.sh`, () => {
      resolve();
    });
  });

  await new Promise(resolve => {
    exec("cat ~/.npmrc", (_, stdout) => {
      t.equal(stdout.includes(FAKE), true);
      resolve();
    });
  });
})

// TODO: monorepo tests
