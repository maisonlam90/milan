import * as Yup from "yup";

export const schema = Yup.object({
  tenant_slug: Yup.string()
    .trim()
    .required("Tenant là bắt buộc"),
  email: Yup.string()
    .trim()
    .email("Email không hợp lệ")
    .required("Email là bắt buộc"),
  password: Yup.string()
    .trim()
    .min(6, "Mật khẩu ít nhất 6 ký tự")
    .required("Mật khẩu là bắt buộc"),
});

export type AuthFormValues = Yup.InferType<typeof schema>;
