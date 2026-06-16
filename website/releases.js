const GITHUB_RELEASES_API = 'https://api.github.com/repos/Ariel-Gal/KodeshMode/releases';
const ALLOWED_LINK_PROTOCOLS = new Set(['https:', 'http:']);

function isSafeHttpUrl(value) {
  try {
    const url = new URL(value, window.location.origin);
    return ALLOWED_LINK_PROTOCOLS.has(url.protocol) ? url.href : null;
  } catch {
    return null;
  }
}

function appendInlineMarkdown(parent, text) {
  const tokenRegex = /(\[([^\]\n]+)\]\(([^)\s]+)\))|(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|(`([^`]+)`)/;
  let currentText = text;
  while (currentText) {
    const match = tokenRegex.exec(currentText);
    if (!match) {
      parent.appendChild(document.createTextNode(currentText));
      break;
    }
    if (match.index > 0) {
      parent.appendChild(document.createTextNode(currentText.slice(0, match.index)));
    }
    if (match[1]) { // Link
      const [, , label, rawUrl] = match;
      const safeUrl = isSafeHttpUrl(rawUrl);
      if (safeUrl) {
        const anchor = document.createElement('a');
        anchor.href = safeUrl;
        anchor.target = '_blank';
        anchor.rel = 'noopener noreferrer';
        anchor.textContent = label;
        parent.appendChild(anchor);
      } else {
        parent.appendChild(document.createTextNode(label));
      }
    } else if (match[4]) { // Bold
      const strong = document.createElement('strong');
      strong.textContent = match[5];
      parent.appendChild(strong);
    } else if (match[6]) { // Italic
      const em = document.createElement('em');
      em.textContent = match[7];
      parent.appendChild(em);
    } else if (match[8]) { // Code
      const code = document.createElement('code');
      code.textContent = match[9];
      parent.appendChild(code);
    }
    currentText = currentText.slice(match.index + match[0].length);
  }
}

function renderMarkdownSafely(markdown, parent) {
  parent.textContent = '';
  const lines = String(markdown || '').replace(/\r\n?/g, '\n').split('\n');
  let paragraphLines = [];
  let activeList = null;
  let activeBlockquote = null;
  let inCodeBlock = false;
  let codeBlockLines = [];

  const flushParagraph = () => {
    if (paragraphLines.length > 0) {
      const p = document.createElement('p');
      appendInlineMarkdown(p, paragraphLines.join(' '));
      if (activeBlockquote) activeBlockquote.appendChild(p);
      else parent.appendChild(p);
      paragraphLines = [];
    }
  };

  const closeList = () => activeList = null;
  const closeBlockquote = () => activeBlockquote = null;

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (inCodeBlock) {
      if (line.startsWith('```')) {
        inCodeBlock = false;
        const pre = document.createElement('pre');
        const code = document.createElement('code');
        code.textContent = codeBlockLines.join('\n');
        pre.appendChild(code);
        if (activeBlockquote) activeBlockquote.appendChild(pre);
        else parent.appendChild(pre);
        codeBlockLines = [];
      } else {
        codeBlockLines.push(rawLine);
      }
      continue;
    }

    if (line.startsWith('```')) {
      flushParagraph();
      closeList();
      inCodeBlock = true;
      continue;
    }

    if (!line) {
      flushParagraph();
      closeList();
      closeBlockquote();
      continue;
    }

    let currentLine = line;
    if (currentLine.startsWith('>')) {
      currentLine = currentLine.substring(1).trim();
      if (!activeBlockquote) {
        flushParagraph();
        closeList();
        activeBlockquote = document.createElement('blockquote');
        parent.appendChild(activeBlockquote);
      }
    } else {
      closeBlockquote();
    }

    const heading = /^(#{1,6})\s+(.+)$/.exec(currentLine);
    if (heading) {
      flushParagraph();
      closeList();
      const h = document.createElement(`h${heading[1].length}`);
      appendInlineMarkdown(h, heading[2]);
      if (activeBlockquote) activeBlockquote.appendChild(h);
      else parent.appendChild(h);
      continue;
    }

    const listItem = /^[-*]\s+(.+)$/.exec(currentLine);
    if (listItem) {
      flushParagraph();
      if (!activeList) {
        activeList = document.createElement('ul');
        if (activeBlockquote) activeBlockquote.appendChild(activeList);
        else parent.appendChild(activeList);
      }
      const li = document.createElement('li');
      appendInlineMarkdown(li, listItem[1]);
      activeList.appendChild(li);
      continue;
    }

    closeList();
    paragraphLines.push(currentLine);
  }

  flushParagraph();
}

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('releases-container');
  if (!container) return;

  const showStatus = (message, isError = false) => {
    container.textContent = '';
    const p = document.createElement('p');
    p.className = isError ? 'fetch-status fetch-status-error' : 'fetch-status';
    p.textContent = message;
    container.appendChild(p);
  };

  fetch(GITHUB_RELEASES_API, {
    headers: { Accept: 'application/vnd.github+json' },
  })
    .then((response) => {
      if (!response.ok) throw new Error(`GitHub API returned ${response.status}`);
      return response.json();
    })
    .then((releases) => {
      container.textContent = '';
      if (!Array.isArray(releases) || releases.length === 0) {
        showStatus('No releases found.');
        return;
      }

      releases.forEach((rel) => {
        const publishedAt = rel && rel.published_at ? new Date(rel.published_at) : null;
        const date = publishedAt && !Number.isNaN(publishedAt.valueOf())
          ? publishedAt.toLocaleDateString('en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })
          : 'Unknown date';

        const el = document.createElement('div');
        el.className = 'release-card reveal';

        const header = document.createElement('div');
        header.className = 'release-header';

        const titleH2 = document.createElement('h2');
        titleH2.className = 'release-title';
        const titleA = document.createElement('a');
        const releaseUrl = isSafeHttpUrl(rel.html_url);
        if (releaseUrl) titleA.href = releaseUrl;
        titleA.target = '_blank';
        titleA.rel = 'noopener noreferrer';
        titleA.textContent = rel.name || rel.tag_name || 'Release';
        titleH2.appendChild(titleA);
        header.appendChild(titleH2);

        const metaDiv = document.createElement('div');
        metaDiv.className = 'release-meta';
        const tagSpan = document.createElement('span');
        tagSpan.className = 'release-tag';
        tagSpan.textContent = rel.tag_name || 'untagged';
        metaDiv.appendChild(tagSpan);
        const dateSpan = document.createElement('span');
        dateSpan.className = 'release-date';
        dateSpan.textContent = date;
        metaDiv.appendChild(dateSpan);
        header.appendChild(metaDiv);

        el.appendChild(header);

        const bodyDiv = document.createElement('div');
        bodyDiv.className = 'release-body';
        renderMarkdownSafely(rel.body || '', bodyDiv);
        el.appendChild(bodyDiv);

        container.appendChild(el);
      });

      setTimeout(() => {
        document.querySelectorAll('.release-card').forEach((el, i) => {
          setTimeout(() => el.classList.add('visible'), i * 80);
        });
      }, 50);
    })
    .catch((err) => {
      console.error(err);
      showStatus('Failed to load releases from GitHub.', true);
    });
});
