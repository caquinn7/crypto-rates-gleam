export function get_app_url() {
    return window['__ENV__']
        ? window.location.origin
        : 'http://localhost:8080'
}
