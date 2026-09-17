# Project Memory & Operating Constraints

### Rule 0: Complete Execution Ownership (Zero User Chores)
- Never ask the user to manually run SQL queries in Supabase dashboards, paste commands into terminals you have access to, or perform manual UI migrations.
- If a database migration, schema change, or data cleanup is required, execute it programmatically via the available CLI, a runner script (e.g. Node/ts-node), or Supabase management API.
- If a build, archive, or deployment is needed, run `xcodebuild` and `vercel deploy --prod` directly.
- The user is the Product Lead and QA tester, NOT your junior developer. Your job is to hand back a completed, verified state.

---

## 1. Operating Team & AI Workflow Hierarchy
- **Developers & Founders:** Adele Roberts & Kate (AKA Studio). Fully active Apple Developer Program account.
- **ChatGPT:** The Strategist / Dragons' Den gatekeeper.
- **Gemini:** Chief Prompter & Systems Architect.
- **Claude (You):** Primary Terminal Builder. You operate inside the local repository via the Terminal CLI (`claude`).
- **Zero Waste / Token Efficiency:** Do not pad responses. Use terminal commands and file manipulation directly. Do not ask Adele to execute manual tasks that you can perform via shell.

---

## 2. Core Stack & Architecture
- **Web / Frontend:** Modern TypeScript, React / Next.js (App Router), Tailwind CSS.
- **Hosting & Deployment:** Vercel (Production & Preview Deployments via Vercel CLI / GitHub integration).
- **Mobile / Native:** Swift / SwiftUI (iOS 27 & iPadOS 27), modern declarative layout patterns, SwiftData / CloudKit.
- **Backend / Services:** Supabase (Auth, Database, Storage, Row-Level Security).
- **Tooling:** Node 20+, npm/pnpm, Git, Vercel CLI, Xcode CLI (`xcodebuild`).
- **Developer Environment:** Xcode 27 on macOS 27.0 (26A428). All test devices (Adele's and Kate's) are on iOS/iPadOS 27 — no need to support or test against older OS versions unless a deployment target is explicitly lowered below 27.

---

## 3. Agent Execution Loop & Rules of Engagement
Always follow the **Plan ➔ Execute ➔ Validate ➔ Ship** loop:

1. **Plan First (Default):**
   - For non-trivial modifications, inspect the existing directory structure and files first.
   - Outline the approach, target files, and edge-case handling before touching code.
   - Do not write code until the plan is established.

2. **No Placeholders:**
   - Never output `// TODO`, `// Add logic here`, or stub implementations.
   - Write production-complete, compile-ready code on every turn.

3. **Autonomous Self-Correction (Max 3 Attempts):**
   - After writing or editing code, execute the relevant build or lint commands in the terminal.
   - If the compiler, linter, or test fails, read `stderr`, patch the affected file, and re-run.
   - Do not stop to prompt the user for trivial type or syntax errors. Only escalate if 3 consecutive automated attempts fail.

---

## 4. Essential Commands & Verification

### Web & API
- **Install:** `npm install`
- **Dev Server:** `npm run dev`
- **Lint / Typecheck:** `npm run lint` && `npx tsc --noEmit`
- **Production Build:** `npm run build`
- **Deployment (Vercel):** `vercel --prod` (or `vercel` for preview builds)

### Native / Mobile (Swift / iOS)
- **Local Test / Build:** `swift test` or `xcodebuild -scheme <AppScheme> -destination 'platform=iOS Simulator,name=iPhone 16' build`
- **Archive (TestFlight / Release):** Run `xcodebuild archive` outputting the `.xcarchive` directly to `~/Library/Developer/Xcode/Archives/<YYYY-MM-DD>/` so it appears in Xcode Organizer ready for distribution.

---

## 5. Code Style & Conventions

### UI & Styling (Web)
- **Tailwind First:** Use native Tailwind utility classes. Do not create separate `.css` files unless defining core design tokens or complex keyframe animations.
- **Component Design:** Keep components modular, accessible, and responsive (mobile-first layout).
- **Icons & Assets:** Use modern SVG icon libraries (e.g., Lucide React). Avoid external heavy icon packages.

### Native / Swift
- Use SwiftUI declarative views with clean state separation (`@State`, `@Binding`, `@Observable`).
- Strictly adhere to modern Swift concurrency (`async`/`await`). Avoid legacy GCD completion handlers where possible.

### Database & Security (Supabase)
- All new database tables must have **Row-Level Security (RLS)** enabled with explicit policies.
- Never expose service role keys in client bundles; use public anon keys for client instances and route privileged logic through secure Edge Functions.

---

## 6. Git & Commit Protocol
- Never commit broken builds. All checks (`build`, `lint`) must pass with exit code `0`.
- Commit messages must be concise and descriptive using the Conventional Commits format:
  - `feat: <brief description>`
  - `fix: <issue resolved>`
  - `refactor: <clean up / restructuring>`
  - `style: <UI polish or layout tweak>`
- Keep diffs tightly scoped to the immediate brief. Do not reformat unrelated files.

---

## 7. Project-Specific Invariants & Schema Contracts
*(Reserved for project-specific rules, table schemas, route deep-links, and role models. Never delete or overwrite these when updating general operating constraints).*