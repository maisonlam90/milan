// 📁 src/app/contexts/auth/schema.js hoặc src/pages/schema.js

import * as Yup from 'yup';

export const schema = Yup.object().shape({
  tenant_id: Yup.string()
    .uuid("Phải là UUID hợp lệ")
    .required("Tenant ID là bắt buộc"),
  email: Yup.string()
    .email("Email không hợp lệ")
    .required("Email là bắt buộc"),
  password: Yup.string()
    .trim()
    .min(6, "Mật khẩu ít nhất 6 ký tự")
    .required("Mật khẩu là bắt buộc"),
});

