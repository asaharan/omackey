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
