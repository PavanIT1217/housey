import globals from 'globals';
import js from '@eslint/js';

export default [
  { ignores: ['js/vendor/**', 'mobile/**', 'node_modules/**'] },
  js.configs.recommended,
  {
    files: ['js/**/*.js'],
    languageOptions: { ecmaVersion: 2023, sourceType: 'module', globals: globals.browser },
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'prefer-const': 'error',
      'no-var': 'error',
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'no-duplicate-imports': 'error',
    },
  },
  {
    files: ['sw.js'],
    languageOptions: { ecmaVersion: 2023, sourceType: 'script', globals: globals.serviceworker },
  },
  {
    files: ['tests/**/*.js', 'eslint.config.js'],
    languageOptions: { ecmaVersion: 2023, sourceType: 'module', globals: globals.node },
  },
];
