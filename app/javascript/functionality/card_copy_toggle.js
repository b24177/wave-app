const CLAMP_THRESHOLD = 1;

const hasOverflow = (element) => element.scrollHeight - element.clientHeight > CLAMP_THRESHOLD;

const configureCardCopy = (cardCopy) => {
  const toggleButton = cardCopy.querySelector('.card-copy-toggle');
  const textBlocks = Array.from(cardCopy.querySelectorAll('.card-copy-text'));

  if (!toggleButton || textBlocks.length === 0) {
    return;
  }

  cardCopy.classList.remove('is-expandable', 'is-expanded');

  textBlocks.forEach((block) => {
    block.classList.add('is-clamped');
  });

  const shouldExpand = textBlocks.some((block) => hasOverflow(block));

  if (!shouldExpand) {
    toggleButton.hidden = true;
    toggleButton.setAttribute('aria-expanded', 'false');
    toggleButton.textContent = 'Read more';
    return;
  }

  cardCopy.classList.add('is-expandable');
  toggleButton.hidden = false;
  toggleButton.setAttribute('aria-expanded', 'false');
  toggleButton.textContent = 'Read more';

  if (toggleButton.dataset.cardCopyBound === 'true') {
    return;
  }

  toggleButton.dataset.cardCopyBound = 'true';
  toggleButton.addEventListener('click', () => {
    const expanded = cardCopy.classList.toggle('is-expanded');
    toggleButton.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    toggleButton.textContent = expanded ? 'Show less' : 'Read more';
  });
};

const refreshCardCopyToggles = () => {
  const cards = document.querySelectorAll('.js-card-copy');
  cards.forEach((card) => configureCardCopy(card));
};

export { refreshCardCopyToggles };
