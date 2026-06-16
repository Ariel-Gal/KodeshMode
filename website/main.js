/* ==========================================================================
   KodeshMode Website — Main JavaScript
   Handles: scroll reveal, navbar, hamburger menu, smooth interactions
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // ── Scroll Reveal ──────────────────────────────────────────────────────
  const revealElements = document.querySelectorAll('.reveal');

  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    },
    {
      root: null,
      rootMargin: '0px 0px -60px 0px',
      threshold: 0.12,
    }
  );

  revealElements.forEach((el) => revealObserver.observe(el));

  // ── Navbar scroll effect ───────────────────────────────────────────────
  const navbar = document.getElementById('navbar');
  let lastScroll = 0;

  const handleScroll = () => {
    const currentScroll = window.scrollY;

    if (currentScroll > 50) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }

    lastScroll = currentScroll;
  };

  window.addEventListener('scroll', handleScroll, { passive: true });
  handleScroll(); // run once on load

  // ── Hamburger menu ─────────────────────────────────────────────────────
  const hamburger = document.getElementById('hamburger');
  const navLinks = document.getElementById('navLinks');

  if (hamburger && navLinks) {
    hamburger.addEventListener('click', () => {
      hamburger.classList.toggle('active');
      navLinks.classList.toggle('open');
      document.body.style.overflow = navLinks.classList.contains('open')
        ? 'hidden'
        : '';
    });

    // Close menu when clicking a nav link
    navLinks.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', () => {
        hamburger.classList.remove('active');
        navLinks.classList.remove('open');
        document.body.style.overflow = '';
      });
    });
  }

  // ── Smooth nav link active state ───────────────────────────────────────
  const sections = document.querySelectorAll('.section[id]');
  const navLinkEls = document.querySelectorAll('.nav-link[href^="#"]');

  const sectionObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const id = entry.target.getAttribute('id');
          navLinkEls.forEach((link) => {
            link.classList.toggle(
              'active',
              link.getAttribute('href') === `#${id}`
            );
          });
        }
      });
    },
    {
      rootMargin: '-40% 0px -55% 0px',
      threshold: 0,
    }
  );

  sections.forEach((section) => sectionObserver.observe(section));

  // ── Animate device-family cards (stagger inside observed container) ────
  const devicesGrid = document.querySelector('.devices-grid');
  if (devicesGrid) {
    const deviceCards = devicesGrid.querySelectorAll('.device-family');

    const deviceObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            deviceCards.forEach((card, i) => {
              setTimeout(() => {
                card.style.opacity = '1';
                card.style.transform = 'translateY(0)';
              }, i * 60);
            });
            deviceObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );

    // Set initial state
    deviceCards.forEach((card) => {
      card.style.opacity = '0';
      card.style.transform = 'translateY(20px)';
      card.style.transition = 'opacity 0.6s cubic-bezier(0.16,1,0.3,1), transform 0.6s cubic-bezier(0.16,1,0.3,1)';
    });

    deviceObserver.observe(devicesGrid);
  }

  // ── Fetch latest GitHub release version ──────────────────────────────────
  const versionBadge = document.getElementById('latest-version-badge');
  if (versionBadge) {
    fetch('https://api.github.com/repos/Ariel-Gal/KodeshMode/releases/latest')
      .then(response => response.json())
      .then(data => {
        if (data && data.tag_name) {
          versionBadge.textContent = data.tag_name;
        }
      })
      .catch(err => console.error('Error fetching latest release:', err));
  }

  // ── Fetch GitHub Contributors ──────────────────────────────────────────────
  const contributorsContainer = document.getElementById('contributors-container');
  if (contributorsContainer) {
    fetch('https://api.github.com/repos/Ariel-Gal/KodeshMode/contributors')
      .then(response => response.json())
      .then(data => {
        if (Array.isArray(data)) {
          contributorsContainer.textContent = '';
          data.forEach(contributor => {
            if (contributor.type !== 'User') return;
            
            const card = document.createElement('a');
            card.href = contributor.html_url;
            card.target = '_blank';
            card.rel = 'noopener noreferrer';
            card.className = 'contributor-card';
            
            const img = document.createElement('img');
            img.src = contributor.avatar_url + '&s=120'; // optimized size
            img.alt = contributor.login;
            img.className = 'contributor-avatar';
            img.loading = 'lazy';
            
            const name = document.createElement('span');
            name.textContent = contributor.login;
            name.className = 'contributor-name';
            
            card.appendChild(img);
            card.appendChild(name);
            contributorsContainer.appendChild(card);
          });
        }
      })
      .catch(err => console.error('Error fetching contributors:', err));
  }

  // ── Fetch Devices from GitHub Manifest ──────────────────────────────────
  const dynamicDevicesTrack = document.getElementById('dynamic-devices-track');
  if (dynamicDevicesTrack) {
    fetch('https://raw.githubusercontent.com/Ariel-Gal/KodeshMode/main/manifest.xml')
      .then(response => response.text())
      .then(xmlText => {
        const regex = /<iq:product\s+id="([^"]+)"/g;
        let match;
        const familyMap = {};

        while ((match = regex.exec(xmlText)) !== null) {
          const id = match[1];
          let family = '';
          let model = '';

          if (id.startsWith('fr')) {
            family = 'Forerunner';
            model = id.replace('fr', '');
          } else if (id.startsWith('fenix')) {
            family = 'fēnix';
            model = id.replace('fenix', '');
          } else if (id.startsWith('epix')) {
            family = 'epix';
            model = id.replace('epix', '');
          } else if (id.startsWith('instinct')) {
            family = 'Instinct';
            model = id.replace('instinct', '');
          } else if (id.startsWith('venu')) {
            family = 'Venu';
            model = id.replace('venu', '');
          } else if (id.startsWith('vivoactive')) {
            family = 'vivoactive';
            model = id.replace('vivoactive', '');
          } else if (id.startsWith('enduro')) {
            family = 'Enduro';
            model = id.replace('enduro', '');
          } else if (id.startsWith('marq')) {
            family = 'MARQ';
            model = id.replace('marq', '');
          } else {
            family = 'Other';
            model = id;
          }

          // Clean up model names
          model = model.replace(/pro/g, ' Pro');
          model = model.replace(/solar/g, ' Solar');
          model = model.replace(/amoled/g, ' AMOLED');
          model = model.replace(/aviator/g, ' Aviator');
          model = model.replace(/plus/g, ' Plus');
          model = model.replace(/sq/g, 'Sq ');
          
          // Fix 'm' suffix vs 'mm' size
          if (model.endsWith('mm')) {
            // Do nothing to the 'm's here
          } else if (model.endsWith('m')) {
            model = model.slice(0, -1) + ' Music';
          }
          
          // Ensure space before mm sizes (e.g. 843mm -> 8 43mm, 2 Pro42mm -> 2 Pro 42mm)
          model = model.replace(/([0-9]{2}mm)/g, ' $1');
          
          model = model.replace(/\s+/g, ' '); // Clean up double spaces
          model = model.trim();
          
          if (model === 'e') model = 'E';
          if (model.startsWith('e ')) model = 'E' + model.slice(1);
          if (model === 'x1') model = 'X1';
          if (!model) model = family;

          // Special capitalizations
          model = model.replace(/Sq /g, 'Sq ').replace(/Music/g, 'Music');

          if (!familyMap[family]) {
            familyMap[family] = new Set();
          }
          familyMap[family].add(model);
        }

        // Build DOM
        dynamicDevicesTrack.textContent = '';
        const createFamilyCard = (familyName, modelsSet) => {
          const df = document.createElement('div');
          df.className = 'device-family';
          const h4 = document.createElement('h4');
          h4.textContent = familyName;
          df.appendChild(h4);
          const dm = document.createElement('div');
          dm.className = 'device-models';
          Array.from(modelsSet).forEach(m => {
            const span = document.createElement('span');
            span.textContent = m;
            dm.appendChild(span);
          });
          df.appendChild(dm);
          return df;
        };

        const families = Object.entries(familyMap);
        if (families.length > 0) {
          // Duplicate for infinite marquee
          families.map(([f, m]) => createFamilyCard(f, m)).forEach(el => dynamicDevicesTrack.appendChild(el));
          families.map(([f, m]) => createFamilyCard(f, m)).forEach(el => dynamicDevicesTrack.appendChild(el));
        }
      })
      .catch(err => console.error('Error fetching manifest:', err));
  }

  // ── Fetch Reviews from Garmin API ───────────────────────────────────────
  const reviewsTrack = document.getElementById('dynamic-reviews-track');
  if (reviewsTrack) {
    const rawUrl = 'https://apps.garmin.com/api/appsLibraryExternalServices/api/asw/apps/ab6e1936-1474-4898-a40d-febd3e3c8aeb/reviews?sortType=CreatedDate&ascending=false&latestVersionOnly=false&pageSize=20&withReviewTextOnly=true&startPageIndex=0';
    // Use a CORS proxy since Garmin's API blocks cross-origin requests from browsers
    const reviewsApiUrl = 'https://corsproxy.io/?' + encodeURIComponent(rawUrl);
    
    fetch(reviewsApiUrl)
      .then(response => {
        if (!response.ok) throw new Error('API restricted or failed');
        return response.json();
      })
      .then(data => {
        if (!Array.isArray(data)) return;
        
        // Filter out reviews below 4 stars and ensure they have text
        const goodReviews = data.filter(review => review.rating >= 4 && review.text && review.text.trim().length > 0);
        
        if (goodReviews.length > 0) {
          reviewsTrack.textContent = ''; // clear loading state safely
          
          const createCard = (review) => {
            const card = document.createElement('div');
            card.className = 'review-card';
            
            const stars = document.createElement('div');
            stars.className = 'stars';
            const starSvgPath = 'M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z';
            for(let i=0; i<5; i++) {
              const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
              svg.setAttribute('viewBox', '0 0 24 24');
              if (i < review.rating) {
                svg.setAttribute('fill', 'currentColor');
              } else {
                svg.setAttribute('fill', 'none');
                svg.setAttribute('stroke', 'currentColor');
                svg.setAttribute('stroke-width', '2');
              }
              const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
              path.setAttribute('d', starSvgPath);
              svg.appendChild(path);
              stars.appendChild(svg);
            }
            card.appendChild(stars);

            const p = document.createElement('p');
            p.className = 'review-text';
            if (/[\u0590-\u05FF]/.test(review.text)) p.dir = 'rtl';
            p.textContent = '"' + review.text + '"'; // Safe from XSS
            card.appendChild(p);

            const authorDiv = document.createElement('div');
            authorDiv.className = 'review-author';
            authorDiv.style.display = 'flex';
            authorDiv.style.flexDirection = 'column';
            authorDiv.style.gap = '0.25rem';
            
            const row = document.createElement('div');
            row.style.display = 'flex';
            row.style.justifyContent = 'space-between';
            row.style.width = '100%';
            
            const nameSpan = document.createElement('span');
            nameSpan.textContent = '— ' + (review.reviewerFullName || 'User'); // Safe
            row.appendChild(nameSpan);
            
            const dateSpan = document.createElement('span');
            dateSpan.style.fontSize = '0.8rem';
            dateSpan.style.fontWeight = '400';
            dateSpan.style.textTransform = 'none';
            dateSpan.style.color = 'var(--text-muted)';
            dateSpan.style.opacity = '0.7';
            dateSpan.textContent = new Date(review.date).toLocaleDateString();
            row.appendChild(dateSpan);
            
            authorDiv.appendChild(row);
            
            const verSpan = document.createElement('span');
            verSpan.style.fontSize = '0.75rem';
            verSpan.style.fontWeight = '500';
            verSpan.style.textTransform = 'none';
            verSpan.style.color = 'var(--accent-mid)';
            verSpan.style.opacity = '0.9';
            const versionStr = review.appExternalVersion ? review.appExternalVersion.replace(' release', '') : '';
            verSpan.textContent = 'Version ' + versionStr;
            authorDiv.appendChild(verSpan);
            
            card.appendChild(authorDiv);
            return card;
          };

          const cards = goodReviews.map(createCard);
          
          if (goodReviews.length >= 4) {
            cards.forEach(c => reviewsTrack.appendChild(c));
            goodReviews.map(createCard).forEach(c => reviewsTrack.appendChild(c));
          } else {
            reviewsTrack.classList.add('no-marquee');
            cards.forEach(c => reviewsTrack.appendChild(c));
          }
        }
      })
      .catch(err => console.log('Could not fetch Garmin reviews (using static placeholders instead):', err));
  }
});
