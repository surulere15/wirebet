/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#000000',
        surface: '#050505',
        surfaceHighlight: '#0a0a0a',
        accent: '#E5BE73',
        primaryText: 'rgba(212, 212, 216, 0.85)', // Zinc-300 / 0.85
        secondaryText: 'rgba(161, 161, 170, 0.7)', // Zinc-400
        tertiaryText: 'rgba(113, 113, 122, 0.45)', // Zinc-500
        microCopy: 'rgba(161, 161, 170, 0.58)',    // Zinc-400 / 0.58 (Phase 2 Visibility)
        border: 'rgba(255, 255, 255, 0.08)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Outfit', 'system-ui', 'sans-serif'],
      },
      animation: {
        'fade-in': 'fadeIn 0.7s ease-out forwards',
        'fade-in-up': 'fadeInUp 0.8s ease-out forwards',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(15px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        }
      }
    },
  },
  plugins: [],
}
