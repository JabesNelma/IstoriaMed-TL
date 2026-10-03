/**
 * Test only environment defaults for the e2e suite.
 *
 * Without this, `npm run test:e2e` fails immediately with
 * "DATABASE_URL is required to start the backend" unless every developer
 * remembers to export the variable by hand. These are the disposable local
 * credentials already used by this project's container, so the suite runs with
 * a single command.
 *
 * `??=` is deliberate: a value that is already present always wins, so CI and
 * any real deployment keep full control over which database is touched. This
 * file must never point at anything but a disposable database.
 */
process.env.DATABASE_URL ??= 'postgresql://istoria:istoria_test@127.0.0.1:5432/istoria_test';
process.env.DATABASE_SSL ??= 'false';

// The suite signs real tokens, so a secret must exist. It never leaves the
// disposable test database.
process.env.JWT_SECRET ??= 'e2e-suite-secret-not-used-outside-tests';
