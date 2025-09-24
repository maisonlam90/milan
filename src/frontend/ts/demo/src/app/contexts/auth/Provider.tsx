import { useEffect, useReducer, ReactNode } from "react";
import isObject from "lodash/isObject";
import isString from "lodash/isString";

import axios from "@/utils/axios";
import { isTokenValid, setSession } from "@/utils/jwt";
import { AuthProvider as SafeAuthProvider } from "./context";
import { User } from "@/@types/user";

// ----------------------------------------------------------------------
// Types

interface AuthState {
  isAuthenticated: boolean;
  isLoading: boolean;
  isInitialized: boolean;
  errorMessage: string | null;
  user: User | null;
}

type AuthAction =
  | { type: "INITIALIZE"; payload: { isAuthenticated: boolean; user: User | null } }
  | { type: "LOGIN_REQUEST" }
  | { type: "LOGIN_SUCCESS"; payload: { user: User } }
  | { type: "LOGIN_ERROR"; payload: { errorMessage: string } }
  | { type: "LOGOUT" };

// ----------------------------------------------------------------------

const initialState: AuthState = {
  isAuthenticated: false,
  isLoading: false,
  isInitialized: false,
  errorMessage: null,
  user: null,
};

const reducer = (state: AuthState, action: AuthAction): AuthState => {
  switch (action.type) {
    case "INITIALIZE":
      return {
        ...state,
        isAuthenticated: action.payload.isAuthenticated,
        isInitialized: true,
        user: action.payload.user,
      };
    case "LOGIN_REQUEST":
      return { ...state, isLoading: true };
    case "LOGIN_SUCCESS":
      return {
        ...state,
        isAuthenticated: true,
        isLoading: false,
        user: action.payload.user,
      };
    case "LOGIN_ERROR":
      return {
        ...state,
        errorMessage: action.payload.errorMessage,
        isLoading: false,
      };
    case "LOGOUT":
      return { ...state, isAuthenticated: false, user: null };
    default:
      return state;
  }
};

// ----------------------------------------------------------------------

interface ProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: ProviderProps) {
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    const init = async () => {
      try {
        const authToken = window.localStorage.getItem("authToken");

        if (authToken && isTokenValid(authToken)) {
          setSession(authToken);

          const response = await axios.get("/user/profile");
          const { user } = response.data;

          dispatch({
            type: "INITIALIZE",
            payload: { isAuthenticated: true, user: user as User },
          });
        } else {
          dispatch({
            type: "INITIALIZE",
            payload: { isAuthenticated: false, user: null },
          });
        }
      } catch (err) {
        console.error(err);
        dispatch({
          type: "INITIALIZE",
          payload: { isAuthenticated: false, user: null },
        });
      }
    };

    init();
  }, []);

  const login = async ({
    tenant_slug,
    email,
    password,
  }: {
    tenant_slug: string;
    email: string;
    password: string;
  }) => {
    dispatch({ type: "LOGIN_REQUEST" });

    try {
      const response = await axios.post("/user/login", {
        tenant_slug,
        email,
        password,
      });

      const { token, user } = response.data;

      if (!isString(token) && !isObject(user)) {
        throw new Error("Response không hợp lệ");
      }

      setSession(token);

      dispatch({ type: "LOGIN_SUCCESS", payload: { user: user as User } });
    } catch (err: any) {
      dispatch({
        type: "LOGIN_ERROR",
        payload: {
          errorMessage: err?.response?.data?.message || "Đăng nhập thất bại",
        },
      });
    }
  };

  const logout = async () => {
    setSession(null);
    dispatch({ type: "LOGOUT" });
  };

  if (!children) return null;

  return (
    <SafeAuthProvider
      value={{
        ...state,
        login,
        logout,
      }}
    >
      {children}
    </SafeAuthProvider>
  );
}
