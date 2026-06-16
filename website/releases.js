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

function appendTextWithLinks(parent, text) {
  const linkPattern = /\[([^\]\n]{1,200})\]\(([^)\s]{1,2048})\)/g;
  let lastIndex = 0;
  let match;

  while ((match = linkPattern.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parent.append(document.createTextNode(text.slice(lastIndex, match.index)));
    }

    const [, label, rawUrl] = match;
    const safeUrl = isSafeHttpUrl(rawUrl);

    if (safeUrl) {
      const anchor = document.createElement('a');
      anchor.href = safeUrl;
      anchor.target = '_blank';
      anchor.rel = 'noopener noreferrer';
      anchor.textContent = label;
      parent.appendChild(anchor);
    } else {
      parent.append(document.createTextNode(label));
    }

    lastIndex = match.index + match[0].length;
  }

  if (lastIndex < text.length) {
    parent.append(document.createTextNode(text.slice(lastIndex)));
  }
}

function appendParagraph(parent, lines) {
  const text = lines.join(' ').trim();
  if (!text) return;

  const paragraph = document.createElement('p');
  appendTextWithLinks(paragraph, text);
  parent.appendChild(paragraph);
}

function renderMarkdownSafely(markdown, parent) {
  parent.textContent = '';

  const lines = String(markdown || '').replace(/\r\n?/g, '\n').split('\n');
  let paragraphLines = [];
  let activeList = null;

  const flushParagraph = () => {
    appendParagraph(parent, paragraphLines);
    paragraphLines = [];
  };

  const closeList = () => {
    activeList = null;
  };

  for (const rawLine of lines) {
    const line = rawLine.trim();

    if (!line) {
      flushParagraph();
      closeList();
      continue;
    }

    const heading = /^(#{2,3})\s+(.+)$/.exec(line);
    if (heading) {
      flushParagraph();
      closeList();
      const level = heading[1].length;
      const h = document.createElement(level === 2 ? 'h2' : 'h3');
      h.textContent = heading[2];
      parent.appendChild(h);
      continue;
    }

    const listItem = /^(?:[-*])\s+(.+)$/.exec(line);
    if (listItem) {
      flushParagraph();
      if (!activeList) {
        activeList = document.createElement('ul');
        parent.appendChild(activeList);
      }
      const li = document.createElement('li');
      appendTextWithLinks(li, listItem[1]);
      activeList.appendChild(li);
      continue;
    }

    closeList();
    paragraphLines.push(line);
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
