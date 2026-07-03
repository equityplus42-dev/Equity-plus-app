# Project Development Roadmap

This outline details the completed milestones and upcoming system iterations.

## Phase 1: Core Database & Backend APIs (Complete)
- [x] Defined relational database models inside Prisma schema.
- [x] Implemented authentication repository, services, Zod schemas, and JWT middleware.
- [x] Configured materialized path structures for hierarchical nodes.
- [x] Coded services to parse, reversing walk paths, and credit multi-level points up to N levels.
- [x] Standardized API JSON payload outputs.

## Phase 2: Client Foundations (Complete)
- [x] Bootstrapped user app and admin app in Flutter.
- [x] Wrote data-transfer parsing models.
- [x] Wrote Providers to maintain state variables.
- [x] Linked ApiClient to perform asynchronous endpoint mapping.

## Phase 3: Premium UI Assemblies (Complete)
- [x] Assembled login and signup screens with input validation.
- [x] Built point cards, stats summaries, copy buttons, and share systems.
- [x] Coded recursive tree indicators to render expanding network cards.
- [x] Added simulation triggers (CSV reports exports, image uploads simulator).

## Phase 4: Production Integrations (Next)
- [ ] Connect production backend to actual cloud TiDB cluster.
- [ ] Bind real Cloudinary credentials.
- [ ] Compile release binaries for Android (APK) and iOS.
