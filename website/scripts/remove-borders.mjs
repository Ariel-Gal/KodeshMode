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

    // Remove the 3-pixel border from all edges (set alpha to 0)
    for (let y = 0; y < info.height; y++) {
      for (let x = 0; x < info.width; x++) {
        if (x < 3 || y < 3 || x >= info.width - 3 || y >= info.height - 3) {
          const idx = (y * info.width + x) * 4;
          data[idx + 3] = 0; // Alpha
        }
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
