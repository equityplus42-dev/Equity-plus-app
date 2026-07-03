# Folder Structure Outline

This workspace is structured as a monorepo containing the Express backend, database scripts, Postman assets, documentation, and two Flutter clients.

```text
ReferralSystem/
│
├── backend/                  # NodeJS + Express backend
│   ├── prisma/               # Schema configuration and DB seeding
│   ├── src/
│   │   ├── config/           # Database, env config, JWT, Cloudinary, and api.js
│   │   ├── controllers/      # Route controllers execution
│   │   ├── middleware/       # JWT auth, admin auth, validations, logger, uploads
│   │   ├── repositories/     # Prisma client CRUD query execution
│   │   ├── services/         # Services layer
│   │   │   ├── qr/           # Modular QR services (generate, decode, share)
│   │   │   ├── referral/     # Modular referral services (generateCode, generateLink, shareLink)
│   │   │   ├── firebase.service.js   # Push notification simulator client
│   │   │   ├── userSearch.service.js  # Downline hierarchy tree searches
│   │   │   └── adminSearch.service.js # Global system directory searcher
│   │   ├── routes/           # Versioned REST API mappings
│   │   │   └── v1/           # API v1 routes directory
│   │   └── validators/       # Zod verification schemas
│   │
│   ├── tests/                # Automated Node HTTP assertions and placeholders
│   ├── .env.example          # Environment keys reference template
│   ├── .env.development      # Local development parameters config
│   └── .env.production       # Production deployment parameters config
│
├── user_app/                 # User-facing client in Flutter
│   └── lib/
│       ├── core/             # Theme system, storage, network client, api_constants.dart
│       ├── models/           # Parsing models
│       ├── providers/        # State managers using ChangeNotifier
│       ├── repositories/     # HTTP endpoint mapping classes
│       └── screens/          # Liquid dark UI slides, lists, and trees
│
├── admin_app/                # Administrator panel client in Flutter
│   └── lib/
│       ├── core/             # Shared themes, network client, api_constants.dart
│       ├── models/           # JSON data classes
│       ├── providers/        # Approvals and settings manager providers
│       └── screens/          # User directories, approvals queues, trees map
│
├── database/                 # Raw SQL equivalent backups
│   ├── schema.sql            # Table structures DDL
│   └── seed_data.sql         # Default admin & config inserts
│
└── docs/                     # SRS and API specifications documentation
```
