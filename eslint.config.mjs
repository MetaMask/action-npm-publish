import base, { createConfig } from '@metamask/eslint-config';
import nodejs from '@metamask/eslint-config-nodejs';

const config = createConfig([
  {
    ignores: ['dist/', 'docs/', '.yarn/'],
  },

  {
    extends: [base, nodejs],

    languageOptions: {
      sourceType: 'module',
    },

    settings: {
      'import-x/extensions': ['.js', '.mjs'],
    },
  },

  {
    files: ['test/**/*.js'],
    languageOptions: {
      sourceType: 'script',
    },
  },
]);

export default config;
