import daisyui from "daisyui"
module.exports = {
  content: ["./index.html", "./src/**/*.{gleam,mjs}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Roboto', 'sans-serif'],
        // display: ['Playfair Display', 'serif'],
      },
    },
  },
  plugins: [daisyui],
  daisyui: {
    themes: ["business"],
  },
};
