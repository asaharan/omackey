const tabs = [...document.querySelectorAll('.shortcut-tabs [role="tab"]')];
const tablist = document.querySelector('.shortcut-tabs');
function selectTab(tab, focus = false) {
  for (const item of tabs) {
    const selected = item === tab;
    item.setAttribute('aria-selected', String(selected));
    item.tabIndex = selected ? 0 : -1;
    item.classList.toggle('tab-active', selected);
    document.getElementById(item.getAttribute('aria-controls')).hidden = !selected;
  }
  if (focus) tab.focus();
}
if (tabs.length) {
  tablist.hidden = false;
  selectTab(tabs[0]);
  for (const tab of tabs) {
    tab.addEventListener('click', () => selectTab(tab));
    tab.addEventListener('keydown', event => {
      let index = tabs.indexOf(tab);
      if (event.key === 'ArrowRight') index = (index + 1) % tabs.length;
      else if (event.key === 'ArrowLeft') index = (index - 1 + tabs.length) % tabs.length;
      else if (event.key === 'Home') index = 0;
      else if (event.key === 'End') index = tabs.length - 1;
      else return;
      event.preventDefault();
      selectTab(tabs[index], true);
    });
  }
}
const copyButton = document.querySelector('#copy-install');
let copyReset;
copyButton.addEventListener('click', async () => {
  const status = document.querySelector('#copy-status');
  clearTimeout(copyReset);
  try {
    await navigator.clipboard.writeText(document.querySelector('#install-code').textContent);
    status.textContent = 'Copied.';
    copyButton.textContent = 'Copied';
    copyReset = setTimeout(() => {
      copyButton.textContent = 'Copy';
      status.textContent = '';
    }, 2000);
  } catch {
    copyButton.textContent = 'Copy';
    status.textContent = 'Select the commands above to copy manually.';
  }
});
