/* ==========================================================================
   KodeshMode Website — Main JavaScript
   Handles: scroll reveal, navbar, hamburger menu, smooth interactions
   ========================================================================== */

function getSafeHttpsUrl(value, allowedHostnames = []) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:') return null;
    if (allowedHostnames.length > 0 && !allowedHostnames.includes(url.hostname)) return null;
    return url;
  } catch {
    return null;
  }
}

function getSizedAvatarUrl(value, size) {
  const url = getSafeHttpsUrl(value, ['avatars.githubusercontent.com']);
  if (!url) return null;
  url.searchParams.set('s', String(size));
  return url.href;
}

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
      document.body.classList.toggle('nav-open', navLinks.classList.contains('open'));
    });

    // Close menu when clicking a nav link
    navLinks.querySelectorAll('.nav-link').forEach((link) => {
      link.addEventListener('click', () => {
        hamburger.classList.remove('active');
        navLinks.classList.remove('open');
        document.body.classList.remove('nav-open');
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
                card.classList.add('device-family-visible');
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
      card.classList.add('device-family-staggered');
    });

    deviceObserver.observe(devicesGrid);
  }

  // ── Fetch latest GitHub release version ──────────────────────────────────
  const versionBadge = document.getElementById('latest-version-badge');
  if (versionBadge) {
    fetch('https://api.github.com/repos/Ariel-Gal/KodeshMode/releases/latest')
      .then(response => {
        if (!response.ok) throw new Error(`GitHub API returned ${response.status}`);
        return response.json();
      })
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
      .then(response => {
        if (!response.ok) throw new Error(`GitHub API returned ${response.status}`);
        return response.json();
      })
      .then(data => {
        if (Array.isArray(data)) {
          contributorsContainer.textContent = '';
          data.forEach(contributor => {
            if (contributor.type !== 'User') return;
            
            const profileUrl = getSafeHttpsUrl(contributor.html_url, ['github.com']);
            if (!profileUrl) return;

            const card = document.createElement('a');
            card.href = profileUrl.href;
            card.target = '_blank';
            card.rel = 'noopener noreferrer';
            card.className = 'contributor-card';
            
            const img = document.createElement('img');
            const avatarUrl = getSizedAvatarUrl(contributor.avatar_url, 120);
            if (avatarUrl) img.src = avatarUrl;
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
      .then(response => {
        if (!response.ok) throw new Error(`Manifest request returned ${response.status}`);
        return response.text();
      })
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

  // ── Reviews privacy note ────────────────────────────────────────────────
  const reviewsTrack = document.getElementById('dynamic-reviews-track');
  if (reviewsTrack) {
    reviewsTrack.textContent = '';
    reviewsTrack.classList.add('no-marquee');

    const p = document.createElement('p');
    p.className = 'fetch-status';
    p.textContent = 'Reviews are available directly on the Garmin Connect IQ store.';
    reviewsTrack.appendChild(p);
  }
});
