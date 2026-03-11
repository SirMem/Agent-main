import { defineConfig, loadEnv } from 'vite';
import vue from '@vitejs/plugin-vue';

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, process.cwd(), '');
    return {
        // Serve the frontend under /agent/ on nginx.
        base: '/agent/',
        plugins: [vue()],
        server: {
            // Keep /api calls working in local `npm run dev`.
            proxy: {
                '/api': {
                    target: env.VITE_API_PROXY_TARGET || 'http://localhost:8066',
                    changeOrigin: true
                }
            }
        }
    };
});
