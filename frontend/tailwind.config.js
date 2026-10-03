/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        brand: {
          yellow: '#FFC400',
          yellowBright: '#FFD21F',
          yellowInk: '#8A5A00',
          red: '#D92D20',
          redBright: '#FF5A4E',
          teal: '#0E8A94',
          tealBright: '#3CC6D0',
          navy: '#0B1220',
          navyCard: '#162036',
          navySunken: '#0E1627',
          borderDark: '#26344F',
          borderLight: '#E6DCA8',
          bgLight: '#FFFCEB',
        }
      },
      fontFamily: {
        display: ['Barlow Semi Condensed', 'sans-serif'],
        body: ['Atkinson Hyperlegible', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      }
    },
  },
  plugins: [],
}
