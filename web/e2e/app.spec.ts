import { test, expect } from '@playwright/test'

test.describe('AskNow Web', () => {
  test('renders the assistant shell immediately', async ({ page }) => {
    await page.goto('/')
    await expect(page.locator('header').getByText('AskNow')).toBeVisible()
    // Mode selector should show built-in modes
    await expect(page.getByRole('button', { name: 'Ask' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Translate' })).toBeVisible()
    // Composer should be present
    await expect(page.getByPlaceholder(/question/i)).toBeVisible()
  })

  test('switches prompt modes', async ({ page }) => {
    await page.goto('/')
    // Click Translate mode
    await page.getByRole('button', { name: 'Translate' }).click()
    // Placeholder should change
    await expect(page.getByPlaceholder(/translate/i)).toBeVisible()
    // Switch to Summarize
    await page.getByRole('button', { name: 'Summarize' }).click()
    await expect(page.getByPlaceholder(/summarize/i)).toBeVisible()
  })

  test('opens settings panel', async ({ page }) => {
    await page.goto('/')
    await page.getByTitle('Settings').click()
    await expect(page.getByRole('button', { name: 'General' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Model Profiles' })).toBeVisible()
    await expect(page.getByRole('button', { name: 'Prompt Modes' })).toBeVisible()
  })

  test('settings has language selector', async ({ page }) => {
    await page.goto('/')
    await page.getByTitle('Settings').click()
    const langSelect = page.locator('select').first()
    await expect(langSelect).toBeVisible()
  })

  test('settings shows model profiles', async ({ page }) => {
    await page.goto('/')
    await page.getByTitle('Settings').click()
    await page.getByRole('button', { name: 'Model Profiles' }).click()
    await expect(page.getByText('Default')).toBeVisible()
  })

  test('mobile viewport renders full-screen', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 })
    await page.goto('/')
    await expect(page.getByText('AskNow')).toBeVisible()
    await expect(page.getByPlaceholder(/question/i)).toBeVisible()
  })

  test('can add a custom prompt mode', async ({ page }) => {
    await page.goto('/')
    await page.getByTitle('Settings').click()
    await page.getByRole('button', { name: 'Prompt Modes' }).click()
    await page.getByText('Add Mode').click()
    const modeButtons = page.locator('button').filter({ hasText: /Custom/ })
    await expect(modeButtons.first()).toBeVisible()
  })

  test('built-in modes cannot be deleted', async ({ page }) => {
    await page.goto('/')
    await page.getByTitle('Settings').click()
    await page.getByRole('button', { name: 'Prompt Modes' }).click()
    // Click on Ask mode in the mode pills (inside the settings panel)
    const modePills = page.locator('.space-y-3 .flex.gap-1.flex-wrap button')
    await modePills.filter({ hasText: 'Ask' }).first().click()
    // Built-in mode notice should appear
    await expect(page.getByText('Built-in Mode')).toBeVisible()
    // No delete button should be present
    await expect(page.getByText('Delete Mode')).not.toBeVisible()
  })
})
