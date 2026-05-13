# UI & Components

## React Component Patterns
- [ ] **Functional components only**: no class components
- [ ] **Props destructured in function signature**: `({ name, age }: Props) =>`
- [ ] **Type component props explicitly**: prefer `Readonly<Props>` for props objects
- [ ] **Import specific React members**: never `React` namespace imports. Import types directly from `react`
- [ ] **Avoid inline lambda functions in JSX**: extract to named const above return. If the child is a PureComponent, inline lambdas break shallow comparison (new function reference on every render)
- [ ] **Clean up global listeners on unmount**: all `window` and `document` event listeners must be removed in cleanup
- [ ] **`useId()` for form-button association**: `<form id={formId}>` + `<Button form={formId}>`
- [ ] **`useWatch()` for reactive form values**: not `useState(form.getValues('field'))`
- [ ] **Controlled/uncontrolled dialog pattern**: support both via prop checking
- [ ] **Dirty field detection before discard**: `Object.keys(form.formState.dirtyFields).length > 0`
- [ ] **Row action pattern for data tables**: discriminated union `{ row, type: 'update' | 'delete' }` state
- [ ] **Loading state distinction**: `isExecuting` for disabling buttons, `isPending` for showing spinners
- [ ] **`useAppAction` hook for server actions**: wraps `next-safe-action` with toast notifications and callbacks
- [ ] **Default values use `satisfies`**: `defaultValues satisfies FormValues` for type-checked defaults
- [ ] **Sub-component composition for large forms**: break into `NamesFields`, `ContactFields`, `AddressFields`
- [ ] **`zodFormResolver` for form validation**: custom resolver wrapping Zod schemas for react-hook-form
- [ ] **Confirmation dialogs for destructive operations**: `ConfirmDialog` component before delete/discard
- [ ] **No form state copied to React state**: rely on react-hook-form's state management
- [ ] **Don't use index as list key**: use a stable unique identifier. Index keys cause bugs with reordering and state preservation
- [ ] **Constants outside components**: if a constant doesn't depend on props/state, define it outside the component body
- [ ] **Separate components into separate files**: if a component grows large enough to have its own JSX tree, extract it
- [ ] **Atomic/design-system components must be generic**: no domain-specific types or business logic in shared UI components. A `Button` should not know what content it displays
- [ ] **Discriminated unions for component variants**: use `{ type: 'default' | 'error' | 'loading' }` instead of multiple boolean props like `isLoading`, `hasError`
- [ ] **Nullability handled in containers, not atoms**: atomic components shouldn't handle null/error states. Move that to container/view components
- [ ] **Cache keys must include all query parameters**: react-query key `['project']` will serve stale data for different project IDs. Include parameters: `['project', projectId, filters]`
- [ ] **React Query auto-refetch over manual refetch**: add dependencies to query keys and let react-query handle refetching. Use `keepPreviousData` and `staleTime` for optimization instead of `useEffect` + `refetch()`
- [ ] **Semantic HTML for accessibility**: use `<a>` with `href` for navigation (not `<button>` with onClick navigation). Links without `href` are not keyboard-accessible
- [ ] **`Composition > Inheritance > Ifing` in generic components**: never add domain-specific if/else branches to generic UI components. Use composition to pass content, not flags to toggle behavior
- [ ] **If a component exists only once, do not make it generic**: abstraction should serve reuse. A header used only in MainLayout doesn't need to be configurable
- [ ] **Form primitives should mimic native HTML API**: allow passing HTML-native props (e.g., checkbox attributes) through to the underlying element. Use `HTMLInputTypeAttribute` instead of defining your own type enum
- [ ] **`useId()` for element IDs**: never use domain values (like database IDs) as HTML element IDs. They may not be unique. Use React's `useId()` hook
- [ ] **Use `children` prop over custom render props for single slots**: `children` is simpler when there's only one content slot. Render props are for multiple named slots
- [ ] **Icons inherit font-size from parent**: don't pass absolute `size` props to icons. Let icons use relative sizing via CSS `font-size` inheritance. Pass optional `className` for overrides
- [ ] **Boolean props without `is` prefix for component APIs**: use `big`, `selected`, `disabled` not `isBig`, `isSelected`. Follows HTML attribute conventions and library conventions (shadcn, Radix)
- [ ] **Extract role checks to named functions**: `isAdmin(user)` instead of inline `user.role === 'admin'`. Reusable, readable, single source of truth
- [ ] **Use `onSelect` not `onClick` for selection interactions**: keyboard selection isn't a "click". `onSelect` is semantically correct and accessible
- [ ] **Handle nullable data at page/fetch level**: make a single null check where data is fetched, not in every child component that consumes it
- [ ] **Single `activeId` state over collection of booleans**: when only one item can be active at a time (e.g., one panel open), store a single `activeId` value, not a map of booleans
- [ ] **Group related form fields into nested objects**: `{ address: { street, city, zip } }` not flat `addressStreet, addressCity, addressZip`. Eliminates manual data transformation between API shape and form shape
- [ ] **`<label htmlFor>` must match actual element `id`**: a label pointing to a nonexistent ID is semantically broken and breaks accessibility
- [ ] **Show 404 for forbidden routes**: when a user lacks permission, display 404 rather than redirecting to login. Don't leak the existence of the resource (GitHub pattern)
- [ ] **No empty rendered elements**: don't render empty `<span>`, `<div>`, or wrappers when content is falsy. Use `{(a || b) && <span>...</span>}` instead of always rendering the element

## Semantic HTML & Accessibility
- [ ] **Use semantic elements over divs**: `nav`, `section`, `header`, `footer`, `main`, `article`, `aside` instead of `<div>` with class names
- [ ] **Correct heading hierarchy**: never skip levels (h1 > h2 > h3). No orphan h3 without h2 above it
- [ ] **One `<main>` per page**: complex layouts with nested `layout.tsx` can accidentally produce multiple `<main>` elements
- [ ] **Sectioning elements create local heading outlines**: wrap cards in `<section>` so their h-tags don't leak to the global document outline. Sections should have a `<header>`
- [ ] **Navigation pattern**: `<nav> <ul> <li> <Link> </li> </ul> </nav>`. `<ul>` can only contain `<li>` children
- [ ] **Use `<time>` for dates**: `<time dateTime="2026-03-23">March 23, 2026</time>` for machine-readable dates
- [ ] **Use `<figure>` for self-contained visual content**: avatars, images, diagrams wrapped in `<figure>` with optional `<figcaption>`
- [ ] **Use `<article>` for independently distributable content**: blog posts, cards, comments that make sense standalone
- [ ] **No block elements inside inline elements**: `<div>` inside `<a>` is invalid HTML. Use `<span>` or restyle the link as block
- [ ] **`<i>` is not for icons**: `<i>` means italic text semantically. Use `<span>` with aria-hidden for decorative icons
- [ ] **`href=""` reloads the page**: if `link` prop can be undefined, `<a href="">` triggers a page reload. Handle missing hrefs explicitly
- [ ] **Use ARIA roles as fallback**: when native elements are hard to style, add ARIA roles to divs (e.g., `role="progressbar"`)

## Tailwind & CSS
- [ ] **No hardcoded color names**: never use `text-white`, `bg-red-600`. Use semantic design tokens: `text-primary`, `bg-accent`. Hardcoded colors break theming/white-labeling
- [ ] **Semantic color naming**: `primary`, `secondary`, `accent`, not `grayBlack`, `lightBlue`. Literal color names break when themes change
- [ ] **No `@apply` for component-specific styles**: extracting Tailwind to CSS classes defeats the purpose. Create React components instead, following Tailwind best practices
- [ ] **No component-specific styles in globals.css**: component styles belong in the component. globals.css is for base/reset styles only
- [ ] **No inline styles**: use Tailwind classes or `className` prop. Inline styles break theming and consistency
- [ ] **CSS gradients over SVG backgrounds**: Tailwind's gradient utilities (`bg-gradient-to-r`, `from-*`, `to-*`) are lighter than SVG background images
- [ ] **No `<br>` for spacing**: use CSS margin/padding/gap for layout spacing. `<br>` is only for line breaks in text content
- [ ] **Pass `className` prop for style overrides**: not custom props like `customClass` or `color`. Standard `className` is the React convention

## Data Table Patterns
- [ ] **Column definitions as generator functions**: `getColumns({ setRowAction }): ColumnDef<T>[]`
- [ ] **Custom `DataTableColumnHeader`**: for sortable columns with proper header rendering
- [ ] **`useDataTable` hook**: encapsulates TanStack table instance with pagination, sorting, filtering
- [ ] **Filter fields typed**: `DataTableFilterField<T>` for type-safe filter definitions
- [ ] **Search params via `nuqs`**: `createSearchParamsCache()` for URL-driven table state
