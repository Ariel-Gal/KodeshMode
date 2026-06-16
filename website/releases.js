document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('releases-container');
  if (!container) return;

  fetch('https://api.github.com/repos/Ariel-Gal/KodeshMode/releases')
    .then(r => r.json())
    .then(releases => {
      container.innerHTML = '';
      if (!Array.isArray(releases) || releases.length === 0) {
        container.innerHTML = '<p style="text-align:center; color: var(--text-muted);">No releases found.</p>';
        return;
      }

      releases.forEach(rel => {
        const date = new Date(rel.published_at).toLocaleDateString('en-US', { 
          year: 'numeric', month: 'long', day: 'numeric' 
        });
        
        // Basic Markdown parsing for the release body
        let bodyHtml = rel.body || '';
        
        // Headers
        bodyHtml = bodyHtml.replace(/^### (.*$)/gim, '<h3>$1</h3>');
        bodyHtml = bodyHtml.replace(/^## (.*$)/gim, '<h2>$1</h2>');
        
        // Bold and Italic
        bodyHtml = bodyHtml.replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>');
        bodyHtml = bodyHtml.replace(/\*(.*)\*/gim, '<em>$1</em>');
        
        // Lists
        bodyHtml = bodyHtml.replace(/^\* (.*$)/gim, '<li>$1</li>');
        bodyHtml = bodyHtml.replace(/^- (.*$)/gim, '<li>$1</li>');
        bodyHtml = bodyHtml.replace(/(<li>.*<\/li>)/gim, '<ul>$1</ul>');
        bodyHtml = bodyHtml.replace(/<\/ul>\n<ul>/gim, '\n'); // merge adjacent uls
        
        // Links
        bodyHtml = bodyHtml.replace(/\[([^\]]+)\]\(([^)]+)\)/gim, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
        
        // Paragraphs
        bodyHtml = bodyHtml.replace(/\n\n/g, '</p><p>');
        bodyHtml = '<p>' + bodyHtml + '</p>';

        const el = document.createElement('div');
        el.className = 'release-card reveal';
        el.innerHTML = `
          <div class="release-header">
            <h2 class="release-title"><a href="${rel.html_url}" target="_blank" rel="noopener noreferrer">${rel.name || rel.tag_name}</a></h2>
            <div class="release-meta">
              <span class="release-tag">${rel.tag_name}</span>
              <span class="release-date">${date}</span>
            </div>
          </div>
          <div class="release-body">
            ${bodyHtml}
          </div>
        `;
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
      container.innerHTML = '<p style="text-align:center; color: #ef4444;">Failed to load releases from GitHub.</p>';
    });
});
