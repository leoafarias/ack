import { defineConfig, devices } from '@playwright/test';
const basePath = (process.env.DOCS_BASE_PATH ?? '').replace(/\/+$/, '');
export default defineConfig({
  testDir: './tests/browser',
  timeout: 30000,
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  workers: 1,
  reporter: 'list',
  use: { baseURL: `http://127.0.0.1:4173${basePath}/`, trace: 'retain-on-failure' },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['iPhone 13'], defaultBrowserType: 'chromium' } },
  ],
  webServer: {
    command: 'python3 scripts/preview.py',
    url: `http://127.0.0.1:4173${basePath}/`,
    reuseExistingServer: false,
    timeout: 30000,
  },
});
