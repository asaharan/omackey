const demoButton = document.querySelector('#run-demo');
const demoBefore = document.querySelector('#demo-before');
const demoStatus = document.querySelector('#demo-status');
const playground = document.querySelector('#playground');
let deleted = false;
demoButton.addEventListener('click', () => {
  deleted = !deleted;
  demoBefore.textContent = deleted ? '' : 'new machine, same habits';
  demoStatus.textContent = deleted ? 'Gone to line start. The period after the cursor stays.' : 'Delete to the start. Keep what comes after.';
  demoButton.textContent = deleted ? 'Reset demo ↺' : 'Try Cmd + Backspace ↗';
  playground.classList.toggle('is-pressed', deleted);
});
const copyButton = document.querySelector('#copy-install');
copyButton.addEventListener('click', async () => {
  const status = document.querySelector('#copy-status');
  try {
    await navigator.clipboard.writeText(document.querySelector('#install-code').textContent);
    status.textContent = 'Copied. Paste into your Omarchy terminal to get started.';
    copyButton.textContent = 'Copied ✓';
  } catch {
    status.textContent = 'Select and copy the three commands above; clipboard access is unavailable.';
  }
});
