import { defineConfig } from 'vitepress'

const repo = 'https://github.com/bircex/macos-flusher'

export default defineConfig({
  lang: 'en-US',
  title: 'MacOS Flusher',
  description: 'Find and delete developer caches on macOS, and see what is filling your disk.',
  base: '/macos-flusher/',
  cleanUrls: true,
  head: [['link', { rel: 'icon', type: 'image/png', href: '/macos-flusher/icon.png' }]],
  themeConfig: {
    logo: '/icon.png',
    nav: [
      { text: 'Guide', link: '/guide/install', activeMatch: '/guide/' },
      { text: 'Reference', link: '/reference/catalog', activeMatch: '/reference/' },
      { text: 'Download', link: `${repo}/releases/latest` },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Install', link: '/guide/install' },
          { text: 'First launch', link: '/guide/first-launch' },
          { text: 'Scan and flush', link: '/guide/usage' },
          { text: 'Read the dashboard', link: '/guide/dashboard' },
          { text: 'Troubleshooting', link: '/guide/troubleshooting' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'What gets cleaned', link: '/reference/catalog' },
          { text: 'Privacy and permissions', link: '/reference/privacy' },
          { text: 'Versions and releases', link: '/reference/releases' },
          { text: 'Build from source', link: '/reference/build' },
        ],
      },
    ],
    socialLinks: [{ icon: 'github', link: repo }],
    search: { provider: 'local' },
    editLink: {
      pattern: `${repo}/edit/main/docs/:path`,
      text: 'Edit this page on GitHub',
    },
    outline: [2, 3],
    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2026 Recep Kızılarslan',
    },
  },
})
