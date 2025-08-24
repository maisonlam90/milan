/**
 * This is simple JWT API for testing purposes.
 * https://github.com/pinia-studio/jwt-api-node
**/

export const JWT_HOST_API =
  window.location.hostname === "localhost" || window.location.port === "5173"
    ? "http://192.168.1.13:3000/"
    : "/api/";
