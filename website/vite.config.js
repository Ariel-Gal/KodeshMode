import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  base: '/KodeshMode/',
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        home: resolve(__dirname, 'home.html'),
        releases: resolve(__dirname, 'releases.html')
      }
    }
  }
});
