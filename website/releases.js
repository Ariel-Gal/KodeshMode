document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('releases-container');
  if (!container) return;

  fetch('https://api.github.com/repos/Ariel-Gal/KodeshMode/releases')
    .then(r => r.json())
    .then(releases => {
      container.textContent = '';
      if (!Array.isArray(releases) || releases.length === 0) {
        const p = document.createElement('p');
        p.textContent = 'No releases found.';
        p.style.textAlign = 'center';
        p.style.color = 'var(--text-muted)';
        container.appendChild(p);
        return;
      }

      releases.forEach(rel => {
        const date = new Date(rel.published_at).toLocaleDateString('en-US', { 
          year: 'numeric', month: 'long', day: 'numeric' 
        });
        
        // Basic Markdown parsing for the release body
        let bodyHtml = rel.body || '';
        bodyHtml = bodyHtml.replace(/^### (.*$)/gim, '<h3>$1</h3>');
        bodyHtml = bodyHtml.replace(/^## (.*$)/gim, '<h2>$1</h2>');
        bodyHtml = bodyHtml.replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>');
        bodyHtml = bodyHtml.replace(/\*(.*)\*/gim, '<em>$1</em>');
        bodyHtml = bodyHtml.replace(/^\* (.*$)/gim, '<li>$1</li>');
        bodyHtml = bodyHtml.replace(/^- (.*$)/gim, '<li>$1</li>');
        bodyHtml = bodyHtml.replace(/(<li>.*<\/li>)/gim, '<ul>$1</ul>');
        bodyHtml = bodyHtml.replace(/<\/ul>\n<ul>/gim, '\n');
        bodyHtml = bodyHtml.replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
        bodyHtml = bodyHtml.replace(/\n\n/g, '</p><p>');
        bodyHtml = '<p>' + bodyHtml + '</p>';

        const el = document.createElement('div');
        el.className = 'release-card reveal';
        
        const header = document.createElement('div');
        header.className = 'release-header';
        
        const titleH2 = document.createElement('h2');
        titleH2.className = 'release-title';
        const titleA = document.createElement('a');
        titleA.href = rel.html_url;
        titleA.target = '_blank';
        titleA.rel = 'noopener noreferrer';
        titleA.textContent = rel.name || rel.tag_name;
        titleH2.appendChild(titleA);
        header.appendChild(titleH2);
        
        const metaDiv = document.createElement('div');
        metaDiv.className = 'release-meta';
        const tagSpan = document.createElement('span');
        tagSpan.className = 'release-tag';
        tagSpan.textContent = rel.tag_name;
        metaDiv.appendChild(tagSpan);
        const dateSpan = document.createElement('span');
        dateSpan.className = 'release-date';
        dateSpan.textContent = date;
        metaDiv.appendChild(dateSpan);
        header.appendChild(metaDiv);
        
        el.appendChild(header);
        
        const bodyDiv = document.createElement('div');
        bodyDiv.className = 'release-body';
        const parsedDoc = new DOMParser().parseFromString(bodyHtml, 'text/html');
        while (parsedDoc.body.firstChild) {
          bodyDiv.appendChild(parsedDoc.body.firstChild);
        }
        el.appendChild(bodyDiv);
        
        container.appendChild(el);
      });

      // Trigger reveal animations for new content
      setTimeout(() => {
        document.querySelectorAll('.release-card').forEach((el, i) => {
          setTimeout(() => el.classList.add('visible'), i * 80);
        });
      }, 50);
    })
    .catch(err => {
      console.error(err);
      container.textContent = '';
      const p = document.createElement('p');
      p.textContent = 'Failed to load releases from GitHub.';
      p.style.textAlign = 'center';
      p.style.color = '#ef4444';
      container.appendChild(p);
    });
});
