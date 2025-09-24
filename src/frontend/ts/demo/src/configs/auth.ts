/**
 * This is simple JWT API for testing purposes.
 * https://github.com/pinia-studio/jwt-api-node
 **/

export const JWT_HOST_API =
  window.location.hostname === "localhost"
    ? "http://localhost:3000"
    : "/api/";