import { expect, test } from '@playwright/test';

const base = (process.env.DOCS_BASE_PATH ?? '').replace(/\/+$/, '');
test('documentation renders and static endpoints work', async ({ page, request }) => {
  const errors: string[] = [];
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(`${base}/core-concepts/schemas/`);
  await expect(page.locator('h1')).toBeVisible();
  await expect(page.locator('a[href="https://github.com/conceptadev/ack"]').first()).toBeAttached();
  const markdown = await request.get(`${base}/llms.mdx/core-concepts/schemas/content.md`);
  expect(markdown.ok()).toBeTruthy();
  expect(await markdown.text()).toContain('Ack');
  const image = await request.get(`${base}/og/core-concepts/schemas/image.png`);
  expect(image.ok()).toBeTruthy();
  expect(image.headers()['content-type']).toContain('image/png');
  const missing = await request.get(`${base}/this-page-does-not-exist/`);
  expect(missing.status()).toBe(404);
  await page.emulateMedia({ colorScheme: 'dark' });
  await expect(page.locator('html')).toHaveClass(/dark/);
  await page.emulateMedia({ colorScheme: 'light' });
  await expect(page.locator('html')).not.toHaveClass(/dark/);
  expect(errors).toEqual([]);
});

test('keyboard search reads the static index and returns a working page', async ({ page }) => {
  const failed: string[] = [];
  page.on('pageerror', (error) => failed.push(error.message));
  await page.goto(`${base}/`);
  await page.keyboard.press('Control+k');
  const dialog = page.getByRole('dialog');
  await expect(dialog).toBeVisible();
  await dialog.locator('input').first().fill('schemas');
  // Base UI search results are buttons that call the framework router.
  const result = dialog.getByRole('button').filter({
    has: page.getByText('Schemas', { exact: true }),
  }).first();
  try {
    await expect(result).toBeVisible();
    await result.click();
    await expect(page).toHaveURL(new RegExp(`${base}/core-concepts/schemas`));
    await expect(page.locator('h1')).toBeVisible();
    expect(failed).toEqual([]);
  } catch (error) {
    console.error('Search dialog state:', await dialog.ariaSnapshot().catch(() => 'Dialog closed'));
    console.error('Browser errors:', failed);
    throw error;
  }
});
