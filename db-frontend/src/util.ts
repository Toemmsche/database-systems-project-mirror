const host = 'http://127.0.0.1:5000'
const baseUrl = '/api/'

export async function restCall(path: string, method: string): Promise<any> {
  return fetch(host + baseUrl + path, {
    method: method
  })
}

export async function REST_GET(path: string): Promise<any> {
  return restCall(path, 'GET');
}

