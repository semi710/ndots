console.log('%c node ', 'background: #00d4aa; color: #0a0e1a; font-weight: bold; padding: 4px 8px; border-radius: 4px;', 'template loaded');

const btn = document.getElementById('action-btn');
let count = 0;

btn.addEventListener('click', () => {
  count++;
  const messages = [
    'Hello from node!',
    'Still here.',
    'You really like this button.',
    'Okay, that\'s enough clicking.'
  ];
  const msg = messages[Math.min(count - 1, messages.length - 1)];
  console.log(`%c ${msg} `, 'background: #111827; color: #00d4aa; padding: 2px 6px; border-radius: 4px;');
  btn.textContent = count === 1 ? 'Clicked!' : `Clicked ${count}x`;
});
