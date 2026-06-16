import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dir = path.join(__dirname, '../public/images/showcase');
const files = fs.readdirSync(dir).filter(f => f.endsWith('.webp') || f.endsWith('.png'));

async function processImage(file) {
  const filePath = path.join(dir, file);
  console.log(`Processing ${file}...`);
  
  try {
    const { data, info } = await sharp(filePath)
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    // We will do a simple color distance from white
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i];
      const g = data[i+1];
      const b = data[i+2];
      
      // Calculate distance from white (255, 255, 255)
      // If it's very bright (almost white), make it transparent, with some alpha blending for antialiased edges
      const brightness = (r + g + b) / 3;
      
      if (brightness > 240) {
        // Map brightness 240-255 to alpha 255-0
        // At 255 (pure white), alpha = 0.
        // At 240, alpha = 255.
        const alpha = Math.max(0, Math.min(255, 255 - ((brightness - 240) * (255 / 15))));
        data[i+3] = Math.min(data[i+3], alpha);
      }
    }

    await sharp(data, {
      raw: {
        width: info.width,
        height: info.height,
        channels: 4
      }
    })
    .webp()
    .toFile(filePath + '.temp.webp');
    
    fs.renameSync(filePath + '.temp.webp', filePath);
    console.log(`Success: ${file}`);
  } catch (err) {
    console.error(`Failed ${file}:`, err);
  }
}

(async () => {
  for (const f of files) {
    await processImage(f);
  }
  console.log('All done!');
})();
