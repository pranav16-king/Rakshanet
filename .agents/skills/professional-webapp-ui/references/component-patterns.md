# Web UI Component Architecture & Patterns

This reference provides core component patterns, composition strategies, and production code checklists for Web UI engineering.

---

## 1. Composition Over Configuration (Slots / AsChild)

Prefer component APIs that compose cleanly using primitives rather than massive prop bags with dozens of flags.

### Example: Composable Card Pattern
```tsx
// Good: Composable, flexible, accessible
<Card>
  <CardHeader>
    <CardTitle>Quarterly Revenue</CardTitle>
    <CardDescription>Comparison against prior financial year</CardDescription>
  </CardHeader>
  <CardContent>
    <RevenueChart data={chartData} />
  </CardContent>
  <CardFooter className="flex justify-between">
    <Button variant="outline">Export CSV</Button>
    <Button>View Full Report</Button>
  </CardFooter>
</Card>
```

---

## 2. Accessible Form Field Pattern

Always associate labels with inputs and connect validation errors using `aria-describedby` and `aria-invalid`.

```tsx
interface FormFieldProps {
  id: string;
  label: string;
  error?: string;
  hint?: string;
  required?: boolean;
  children: (props: {
    id: string;
    'aria-invalid'?: boolean;
    'aria-describedby'?: string;
  }) => React.ReactNode;
}

export function FormField({ id, label, error, hint, required, children }: FormFieldProps) {
  const hintId = hint ? `${id}-hint` : undefined;
  const errorId = error ? `${id}-error` : undefined;
  const describedBy = [hintId, errorId].filter(Boolean).join(' ') || undefined;

  return (
    <div className="flex flex-col gap-1.5 mb-4">
      <label htmlFor={id} className="text-sm font-medium text-slate-700 dark:text-slate-200">
        {label}
        {required && <span className="text-red-500 ml-0.5" aria-hidden="true">*</span>}
      </label>

      {children({
        id,
        'aria-invalid': !!error,
        'aria-describedby': describedBy,
      })}

      {hint && !error && (
        <p id={hintId} className="text-xs text-slate-500">{hint}</p>
      )}

      {error && (
        <p id={errorId} role="alert" className="text-xs text-red-600 font-medium">
          {error}
        </p>
      )}
    </div>
  );
}
```

---

## 3. Responsive Modal & Dialog Pattern

- **Focus Trap**: Keep focus strictly inside the dialog when open.
- **Escape Key**: Pressing `Escape` closes the modal immediately.
- **Backdrop Dismiss**: Clicking outside dismisses non-critical modals.
- **Scroll Lock**: Lock body scroll (`overflow: hidden`) when modal is mounted.
- **Return Focus**: Return focus to the trigger button when dismissed.

---

## 4. Skeleton Loader Pattern

Skeletons must match the dimensions and line counts of actual loaded content to prevent Cumulative Layout Shift (CLS):

```html
<div class="animate-pulse space-y-3" role="status" aria-label="Loading profile">
  <div class="h-12 w-12 rounded-full bg-slate-200 dark:bg-slate-700"></div>
  <div class="h-4 w-3/4 rounded bg-slate-200 dark:bg-slate-700"></div>
  <div class="h-3 w-1/2 rounded bg-slate-200 dark:bg-slate-700"></div>
</div>
```
