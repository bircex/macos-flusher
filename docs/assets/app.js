const releaseUrl = 'https://api.github.com/repos/bircex/macos-flusher/releases/latest'

function fill(name, text) {
  document.querySelectorAll(`[data-${name}]`).forEach((element) => {
    element.textContent = text
    element.hidden = false
  })
}

async function showLatestRelease() {
  try {
    const response = await fetch(releaseUrl, { headers: { Accept: 'application/vnd.github+json' } })
    if (!response.ok) return
    const release = await response.json()
    fill('version', `Version ${release.tag_name.replace(/^v/, '')}`)
    fill('released', `Released ${new Date(release.published_at).toLocaleDateString('en', { year: 'numeric', month: 'long', day: 'numeric' })}`)
    const image = release.assets.find((asset) => asset.name === 'MacOS-Flusher.dmg')
    if (image) fill('size', `${(image.size / 1e6).toFixed(1)} MB download`)
  } catch {
    return
  }
}

document.querySelectorAll('.copy').forEach((button) => {
  button.addEventListener('click', async () => {
    await navigator.clipboard.writeText(button.parentElement.querySelector('pre').textContent.trim())
    button.classList.add('copied')
    setTimeout(() => button.classList.remove('copied'), 1600)
  })
})

showLatestRelease()
