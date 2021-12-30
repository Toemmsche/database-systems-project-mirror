import {AppRoutingModule} from "./app/app-routing.module";

const host = 'http://127.0.0.1:5000'
const baseUrl = '/api/'

export async function restCall(path: string, method: string, body: object | null): Promise<any> {
  if (method == 'GET') {
    return fetch(host + baseUrl + path, {
      method: method
    })
  } else {
    return fetch(host + baseUrl + path, {
      method: method,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    })
  }

}

export async function REST_GET(path: string): Promise<any> {
  return restCall(path, 'GET', null);
}

export async function REST_POST(path: string, body: object): Promise<any> {
  return restCall(path, 'POST', body)
}

