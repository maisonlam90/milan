import { Button, Input } from "components/ui";

export default function DynamicForm({ fields, form, onSubmit }) {
  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      {fields.map((field) => (
        <Input
          key={field.name}
          label={field.label}
          type={field.type === "number" ? "number" : "text"}
          placeholder={field.label}
          {...form.register(field.name, {
            required: `${field.label} là bắt buộc`,
          })}
          error={form.formState.errors?.[field.name]?.message}
        />
      ))}
      <Button type="submit" className="w-full">
        Lưu
      </Button>
    </form>
  );
}
