export function get_app_url() {
  return window['__ENV__']
    ? window.location.origin
    : 'https://crypto-rates.fly.dev';
}
