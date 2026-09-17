# Project Memory & Operating Constraints

### Rule 0: Complete Execution Ownership (Zero User Chores)
- Never ask the user to manually run SQL queries in Supabase dashboards, paste commands into terminals you have access to, or perform manual UI migrations.
- If a database migration, schema change, or data cleanup is required, execute it programmatically via the available CLI, a runner script (e.g. Node/ts-node), or Supabase management API.
- If a build, archive, or deployment is needed, run `xcodebuild` and `vercel deploy --prod` directly.
- The user is the Product Lead and QA tester, NOT your junior developer. Your job is to hand back a completed, verified state.

---

## 1. Founders, Team Credentials & Tool Ecosystem

### Team Profile
- **Founders & Core Builders:** Adele Roberts & Kate (AKA Studio).
- **Apple Developer Program:** Active, fully enrolled Apple Developer account.
- **Distribution Scope:** Native iOS and iPadOS builds ready for direct hardware deployment, TestFlight, and App Store submission. Never question developer access or treat bundle signing/provisioning as a barrier.

### The AI Division of Labour
- **ChatGPT (The Strategist / Dragon):** Operates as the Dragons' Den inquisitor. Puts all concepts through the wringer, stress-tests product viability, challenges utility, and sharpens business loops before engineering begins.
- **Gemini (Chief Prompter & Systems Architect):** Defines high-level technical architectures, schemas, visual constraints, and crafts exact, zero-fluff prompts for Claude.
- **Claude (The Terminal Builder):** Lives and executes inside the integrated Terminal via CLI (`claude`). Runs builds, generates code, edits files, and handles all local execution.

---

## 2. Token-Efficiency & Automation Guardrails
- **Max Token Efficiency:** Never waste tokens on conversational padding, repeated preambles, or speculative file scans. Choose the cheapest, most direct path (e.g., local shell scripts and CLI over expensive API wrappers).
- **Zero Free-Tier Waste:** If a task can be performed for free or locally via existing terminal tools, do it that way.
- **No Manual Labour for Adele:** If Claude has shell or file system permissions, Claude performs the move, deletion, file creation, or build. Never instruct Adele to perform manual directory housekeeping or code splicing.

---

## 3. Core Stack & Architecture
- **Web / Frontend:** Modern TypeScript, React / Next.js (App Router), Tailwind CSS.
- **Hosting & Deployment:** Vercel (Production & Preview Deployments via Vercel CLI / GitHub integration).
- **Mobile / Native:** Swift / SwiftUI (iOS 27 & iPadOS 27), modern declarative layout patterns, SwiftData / CloudKit.
- **Backend / Services:** Supabase (Auth, Database, Storage, Row-Level Security).
- **Tooling:** Node 20+, npm/pnpm, Git, Vercel CLI, Xcode CLI (`xcodebuild`).
- **Developer Environment:** Xcode 27 on macOS 27.0 (26A428). All test devices (Adele's and Kate's) are on iOS/iPadOS 27 — no need to support or test against older OS versions unless a deployment target is explicitly lowered below 27.

---

## 4. Agent Execution Loop & Rules of Engagement
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

## 5. Essential Commands & Verification

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

## 6. Code Style & Conventions

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

## 7. Git & Commit Protocol
- Never commit broken builds. All checks (`build`, `lint`) must pass with exit code `0`.
- Commit messages must be concise and descriptive using the Conventional Commits format:
  - `feat: <brief description>`
  - `fix: <issue resolved>`
  - `refactor: <clean up / restructuring>`
  - `style: <UI polish or layout tweak>`
- Keep diffs tightly scoped to the immediate brief. Do not reformat unrelated files.