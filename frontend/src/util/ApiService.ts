import ServerError from "./ServerError";
import {environment} from "../environments/environment";

const BASE_URL = environment.API_URL;
console.log("API_URL:", BASE_URL);
const URL_PREFIX = "/api/"

export enum HttpMethod {
  POST = "POST",
  GET = "GET",
  PUT = "PUT",
  DELETE = "DELETE",
}

export async function REST_CALL(path: string, method: string, data?: object | null): Promise<Response> {
  const config: RequestInit = {
    method: method.toString()
  };
  if (data) {
    config.body = JSON.stringify(data);
    // default to JSON
    config.headers = {...config.headers, "Content-Type": "application/json"};
  }
  return fetch(BASE_URL + URL_PREFIX + path, config)
    .catch((reason) => {
      return Promise.reject(`${method} ${path} failed\nreason: ${reason}\nrequest body: ${JSON.stringify(data)}`);
    })
    .then(async (response) => {
      switch (response.status) {
        case 200:
        case 201:
        case 204: {
          // Accepted
          console.debug(`${method} ${path} returned code ${response.status}-${response.statusText}`);
          return response;
        }
        default: {
          // Indicates error / unexpected behaviour
          // Check for error message in JSON
          const errorMessage = await response
            .json()
            .then((json) => {
              return JSON.stringify(json);
            })
            .catch(() => "");
          return Promise.reject(new ServerError(response.status, response.statusText, errorMessage));
        }
      }
    });
}

export async function REST_GET(path: string): Promise<Response> {
  return REST_CALL(path, HttpMethod.GET, null);
}

export async function REST_POST(path: string, data: object): Promise<Response> {
  return REST_CALL(path, HttpMethod.POST, data);
}

