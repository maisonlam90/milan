import { Link } from "react-router-dom";
import { EnvelopeIcon, LockClosedIcon } from "@heroicons/react/24/outline";
import { useForm, SubmitHandler } from "react-hook-form";
import { yupResolver } from "@hookform/resolvers/yup";

import Logo from "@/assets/appLogo.svg?react";
import { Button, Card, Checkbox, Input, InputErrorMsg } from "@/components/ui";
import { useAuthContext } from "@/app/contexts/auth/context";
import { Page } from "@/components/shared/Page";

import { schema, AuthFormValues } from "./schema";

export default function SignIn() {
  const { login, errorMessage } = useAuthContext();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<AuthFormValues>({
    resolver: yupResolver(schema),
    defaultValues: {
      tenant_slug: "",
      email: "",
      password: "",
    },
  });

  const onSubmit: SubmitHandler<AuthFormValues> = (data) => {
    login(data);
  };

  return (
    <Page title="Login">
      <main className="min-h-100vh grid w-full grow grid-cols-1 place-items-center">
        <div className="w-full max-w-[26rem] p-4 sm:px-5">
          <div className="text-center">
            <Logo className="mx-auto size-60" />
            <div className="mt-4">
              <h2 className="text-2xl font-semibold text-gray-600 dark:text-dark-100">
                Welcome Back
              </h2>
              <p className="text-gray-400 dark:text-dark-300">
                Please sign in to continue
              </p>
            </div>
          </div>

          <Card className="mt-5 rounded-lg p-5 lg:p-7">
            <form onSubmit={handleSubmit(onSubmit)} autoComplete="off">
              <div className="space-y-4">
                <Input
                  label="Tenant Slug"
                  placeholder="your-company"
                  {...register("tenant_slug")}
                  error={errors?.tenant_slug?.message}
                />

                <Input
                  label="Email"
                  placeholder="Enter your email"
                  prefix={<EnvelopeIcon className="size-5" strokeWidth="1" />}
                  {...register("email")}
                  error={errors?.email?.message}
                />

                <Input
                  label="Password"
                  placeholder="Enter Password"
                  type="password"
                  prefix={<LockClosedIcon className="size-5" strokeWidth="1" />}
                  {...register("password")}
                  error={errors?.password?.message}
                />
              </div>

              <div className="mt-2">
                <InputErrorMsg when={!!errorMessage}>
                  {errorMessage}
                </InputErrorMsg>
              </div>

              <div className="mt-4 flex items-center justify-between space-x-2">
                <Checkbox label="Remember me" />
                <a
                  href="#"
                  className="text-xs text-gray-400 hover:text-gray-800 dark:text-dark-300 dark:hover:text-dark-100"
                >
                  Forgot Password?
                </a>
              </div>

              <Button type="submit" className="mt-5 w-full" color="primary">
                Sign In
              </Button>
            </form>

            <div className="mt-4 text-center text-xs-plus">
              <p>
                <span>Don&#39;t have an account?</span>{" "}
                <Link
                  className="text-primary-600 hover:text-primary-800 dark:text-primary-400 dark:hover:text-primary-600"
                  to="/pages/sign-up-v1"
                >
                  Create account
                </Link>
              </p>
            </div>
          </Card>
        </div>
      </main>
    </Page>
  );
}
