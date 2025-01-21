import daisyui from "daisyui"

module.exports = {
  content: ["./index.html", "./src/**/*.{gleam,mjs}"],
  theme: {
    extend: { },
  },
  plugins: [daisyui],
  daisyui: {
    themes: ["business"],
  },
};
