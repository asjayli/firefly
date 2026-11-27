# Data, architecture and state diagrams

### Step 4: ERD Creation

**Objective**: Document database schema and relationships

**Syntax:**

```mermaid
erDiagram
    USER ||--o{ BOOKING : creates
    ACCOMMODATION ||--o{ BOOKING : "booked for"
    USER {
        uuid id PK
        string email UK
        string name
        timestamp created_at
    }
    BOOKING {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        date check_in
        date check_out
        enum status
    }
    ACCOMMODATION {
        uuid id PK
        string name
        text description
        decimal price_per_night
    }
```

**Relationship Types:**

- `||--||` - One to one
- `||--o{` - One to many
- `}o--o{` - Many to many
- `||--o|` - One to zero or one

**Cardinality Symbols:**

- `||` - Exactly one
- `o|` - Zero or one
- `}o` - Zero or more
- `}|` - One or more

**Example - Full Hospeda ERD:**

```mermaid
erDiagram
    USER ||--o{ BOOKING : creates
    USER ||--o{ REVIEW : writes
    USER ||--o{ ACCOMMODATION : owns
    ACCOMMODATION ||--o{ BOOKING : "has bookings"
    ACCOMMODATION ||--o{ REVIEW : "has reviews"
    ACCOMMODATION }o--o{ AMENITY : includes
    BOOKING ||--|| PAYMENT : "has payment"

    USER {
        uuid id PK
        string clerk_id UK
        string email UK
        string name
        enum role
        timestamp created_at
    }

    ACCOMMODATION {
        uuid id PK
        uuid owner_id FK
        string name
        text description
        decimal price_per_night
        int max_guests
        enum status
    }

    BOOKING {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        date check_in
        date check_out
        int guests
        enum status
        decimal total_price
    }

    REVIEW {
        uuid id PK
        uuid user_id FK
        uuid accommodation_id FK
        int rating
        text comment
        timestamp created_at
    }

    PAYMENT {
        uuid id PK
        uuid booking_id FK
        string mercadopago_id UK
        decimal amount
        enum status
        timestamp processed_at
    }

    AMENITY {
        uuid id PK
        string name
        string icon
    }
```

**Validation:**

- [ ] All entities defined
- [ ] Relationships accurate
- [ ] Cardinality correct
- [ ] Primary/Foreign keys marked

**Output**: ERD diagram

### Step 5: C4 Architecture Diagrams

**Objective**: Document system architecture at different levels

**Context Level** (System in environment):

```mermaid
C4Context
    title System Context - Hospeda Platform

    Person(guest, "Guest", "Tourist looking for accommodation")
    Person(owner, "Owner", "Accommodation owner")
    System(hospeda, "Hospeda Platform", "Tourism booking platform")

    System_Ext(clerk, "Clerk", "Authentication provider")
    System_Ext(mercadopago, "Mercado Pago", "Payment processor")
    System_Ext(email, "Email Service", "Transactional emails")

    Rel(guest, hospeda, "Searches and books", "HTTPS")
    Rel(owner, hospeda, "Manages listings", "HTTPS")
    Rel(hospeda, clerk, "Authenticates users", "API")
    Rel(hospeda, mercadopago, "Processes payments", "API")
    Rel(hospeda, email, "Sends notifications", "SMTP")
```

**Container Level** (Applications and data stores):

```mermaid
C4Container
    title Container - Hospeda Platform

    Person(user, "User")

    Container(web, "Web App", "Astro + React", "Public-facing website")
    Container(admin, "Admin Panel", "TanStack Start", "Management interface")
    Container(api, "API", "Hono", "Backend services")
    ContainerDb(db, "Database", "PostgreSQL", "Stores all data")

    Rel(user, web, "Uses", "HTTPS")
    Rel(user, admin, "Manages", "HTTPS")
    Rel(web, api, "Calls", "JSON/HTTPS")
    Rel(admin, api, "Calls", "JSON/HTTPS")
    Rel(api, db, "Reads/Writes", "SQL")
```

**Component Level** (Internal structure):

```mermaid
C4Component
    title Components - API Application

    Container(api, "API", "Hono")

    Component(routes, "Routes", "Hono Router", "HTTP endpoints")
    Component(services, "Services", "Business Logic", "Domain operations")
    Component(models, "Models", "Data Access", "DB operations")
    Component(middleware, "Middleware", "Cross-cutting", "Auth, logging, errors")

    Rel(routes, middleware, "Uses")
    Rel(routes, services, "Calls")
    Rel(services, models, "Uses")
    Rel(models, db, "Queries")
```

**Validation:**

- [ ] Appropriate level selected
- [ ] All systems/containers shown
- [ ] Relationships clear
- [ ] External systems identified

**Output**: C4 architecture diagrams

### Step 6: State Diagram Creation

**Objective**: Document state machines and lifecycles

**Syntax:**

```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Confirmed : Payment Success
    Pending --> Cancelled : Payment Failed
    Pending --> Cancelled : User Cancels
    Confirmed --> CheckedIn : Check-in Date
    Confirmed --> Cancelled : Cancellation Request
    CheckedIn --> CheckedOut : Check-out Date
    CheckedOut --> Reviewed : User Submits Review
    CheckedOut --> [*] : 30 Days Elapsed
    Reviewed --> [*]
    Cancelled --> [*]
```

**Example - Booking Lifecycle:**

```mermaid
stateDiagram-v2
    [*] --> Draft : Create Booking

    state "Pending Payment" as Pending
    state "Payment Processing" as Processing

    Draft --> Pending : Submit Booking
    Pending --> Processing : Initiate Payment

    Processing --> Confirmed : Payment Approved
    Processing --> PaymentFailed : Payment Declined

    PaymentFailed --> Pending : Retry Payment
    PaymentFailed --> Cancelled : Max Retries

    Confirmed --> Active : Check-in Date Reached
    Active --> Completed : Check-out Date Reached

    Confirmed --> CancelRequested : Cancellation Request
    CancelRequested --> RefundProcessing : Approve Cancellation
    RefundProcessing --> Cancelled : Refund Complete

    Completed --> [*]
    Cancelled --> [*]

    note right of Confirmed
        Owner notified
        Calendar blocked
    end note

    note right of Completed
        Review requested
        Payment released
    end note
```

**Validation:**

- [ ] All states defined
- [ ] Transitions logical
- [ ] Start/end states marked
- [ ] Notes explain key states

**Output**: State diagram
