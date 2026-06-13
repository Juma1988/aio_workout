# AIO Workout — Backend Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App (Flutter)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Steps    │  │ Workouts │  │  Weight  │  │ Achievements │   │
│  │  Tracker  │  │   Sync   │  │  Log     │  │   Sync       │   │
│  └─────┬────┘  └─────┬────┘  └────┬─────┘  └──────┬───────┘   │
└────────┼─────────────┼────────────┼────────────────┼───────────┘
         │             │            │                │
         ▼             ▼            ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     API Gateway (Nginx)                          │
│              Rate Limiting · SSL Termination · CORS               │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FastAPI Application                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Auth    │  │   Steps  │  │ Workouts │  │  Analytics   │   │
│  │ Service  │  │  Service │  │ Service  │  │   Service    │   │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └──────┬───────┘   │
│        │             │             │               │             │
│  ┌─────┴────┐  ┌─────┴────┐  ┌────┴─────┐  ┌─────┴──────┐    │
│  │  Goals   │  │ Devices  │  │Social   │  │ Notifications│    │
│  │ Service  │  │ Service  │  │Service  │  │   Service    │    │
│  └─────┬────┘  └─────┬────┘  └────┬─────┘  └─────┬──────┘    │
└────────┼─────────────┼────────────┼───────────────┼────────────┘
         │             │            │               │
         ▼             ▼            ▼               ▼
┌────────────────┐  ┌────────────────┐  ┌────────────────────┐
│   PostgreSQL   │  │     Redis      │  │   Firebase / APNs  │
│   (Primary)    │  │   (Cache +     │  │   (Push Notif)     │
│                │  │    Sessions)   │  │                    │
└────────┬───────┘  └────────────────┘  └────────────────────┘
         │
         ▼
┌────────────────┐
│   PostgreSQL   │
│   (Read        │
│    Replica)    │
└────────────────┘
```

## Pattern: Modular Monolith → Microservices-Ready

- Start as a modular monolith (single deployable, clean module boundaries)
- Each module has its own service layer, DTOs, and DB access
- Ready to extract into microservices by promoting module interfaces to gRPC/REST

## Communication

- **Mobile ↔ API**: REST (OpenAPI 3.1 spec) — simpler for Flutter HTTP clients
- **Internal**: Direct function calls (modular monolith), events for cross-module triggers
- **Async**: Background task queue (Redis-based) for aggregation, notifications

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| API Framework | FastAPI (Python 3.12) | Async, automatic OpenAPI, Pydantic validation |
| Database | PostgreSQL 16 | JSONB for flexible step metadata, strong consistency |
| Cache | Redis 7 | Session tokens, rate limiting, aggregated stats cache |
| Task Queue | Redis + ARQ | Background aggregation, push notifications |
| Auth | JWT (access) + Refresh tokens | Stateless auth, short-lived access tokens |
| Push Notifications | Firebase Admin SDK | Cross-platform (APNs + FCM) |
| Container | Docker + Docker Compose | Reproducible dev/prod environments |
| Reverse Proxy | Nginx | SSL termination, rate limiting, static files |
