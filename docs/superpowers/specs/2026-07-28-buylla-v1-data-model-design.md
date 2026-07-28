# Buylla v1 Data Model Design

## Purpose

Buylla v1 is a headless monetization and checkout control plane for digital
products, services, and subscriptions.

Buylla owns catalog configuration, campaigns, checkout orchestration, and a
normalized view of purchase outcomes. The client business owns its customer
experience and product access. The connected payment provider owns card data,
money movement, invoices, renewals, proration, and authoritative payment and
subscription state.

The first implementation will support Stripe. Provider-facing code will use a
small adapter boundary so another provider can be added later without shaping
the catalog around Stripe.

## Modeling Approach

Model one complete example before writing SQL:

1. Write concrete example records.
2. Identify which facts have independent identity.
3. Assign ownership and tenant boundaries.
4. Write invariants in plain language.
5. Draw relationships.
6. Turn the model into tables and constraints.
7. Add indexes from known access patterns.

Begin with the catalog:

```text
Company
  Product
    Price
      Offer
        Introductory phases
  Campaign
    Entry offers
    Contextual offer links
```

Do not model the entire billing lifecycle at once. First prove that a company
can publish one campaign, retrieve it, and create one safe test checkout.

## Responsibility Boundaries

### Buylla

- Companies, team memberships, customers, and API keys
- Products, prices, offers, and campaigns
- Test and live catalog separation
- Test-to-live catalog promotion
- Resolved client-facing campaign documents
- Checkout snapshots and idempotency
- Provider checkout creation
- Provider event verification and deduplication
- Purchase and subscription mirrors
- Signed outbound client webhooks

### Client business

- End-user authentication
- Product, pricing, campaign, and checkout UI
- Interpretation of campaign relationship types
- Entitlements, fulfillment, and access control

### Payment provider

- Card collection and payment-method storage
- Payment authentication and money movement
- Invoices and recurring collection
- Renewal schedules, retries, and proration
- Refund execution and authoritative financial state

## Tenant and Identity Model

### `users`

Buylla dashboard identities.

Core data:

- Internal UUID
- Email and authentication state
- Created and updated timestamps

### `companies`

The tenant and ownership boundary.

Core data:

- Internal UUID
- Stable company code
- Display name
- Created and updated timestamps

### `company_memberships`

Many-to-many relationship between users and companies.

Initial roles:

- `owner`
- `admin`
- `product_manager`
- `developer`
- `viewer`

Permissions remain defined in application code for v1. The `developer` role can
read catalog resources and update metadata without changing products, prices,
offers, or campaigns.

Metadata updates use dedicated endpoints and permission
`catalog.metadata.write`. Financial catalog changes require `catalog.write`.

### `customers`

End users belonging to a client business. Customers do not authenticate with
Buylla.

Core data:

- Internal UUID
- Company UUID
- Mode: `test` or `live`
- Client-provided external customer ID
- Editable email and name
- JSON metadata

Invariant:

```text
(company_id, mode, external_customer_id) is unique
```

Email is searchable profile data, not durable identity.

### `api_keys`

Server-side credentials that derive the company, mode, and allowed operations.

Only a key prefix and cryptographic hash are stored. Keys support expiration,
rotation, revocation, scopes, and last-used auditing.

The basic implementation has one secret server key type. Browser-safe
publishable keys are deferred until a direct browser integration requires them.

## Catalog Model

### `products`

What a company sells.

Examples:

- Pro Plan
- Premium Plan
- Express Service
- One-time Report

Core data:

- Internal UUID
- Company UUID
- Mode
- Company-scoped stable code
- Name and description
- Status
- JSON metadata for features and presentation details

Invariant:

```text
(company_id, mode, code) is unique
```

Use `Product`, not `Plan`, because the catalog includes subscriptions, services,
and one-time purchases.

### `prices`

Stable billing choices for products.

Core data:

- Internal UUID
- Company UUID and mode
- Product UUID
- Company-scoped stable code
- Integer amount in minor currency units
- ISO currency code
- Billing type: `one_time` or `recurring`
- Recurring period unit and count
- Status
- JSON metadata

Examples:

```text
unit=month, count=1  -> monthly
unit=month, count=3  -> every three months
unit=week, count=2   -> every two weeks
unit=year, count=1   -> yearly
```

A product may have multiple prices with the same period:

```text
pro-monthly-standard -> $19.99/month
pro-monthly-low      -> $3.88/month
```

The reason determines whether to create a price or an offer:

- A permanent alternative amount is another price.
- A temporary or contextual adjustment belongs to an offer.
- A limited introductory schedule belongs to offer phases.

Used prices are immutable. Changing an amount, currency, or billing period
creates a replacement price.

### `offers`

A specific commercial configuration for one base price.

Core data:

- Internal UUID
- Company UUID and mode
- Stable company-scoped code
- Base price UUID
- Integer revision
- Status: `draft`, `published`, or `archived`
- Optional availability start and end
- JSON presentation metadata

An offer is neither a product nor a price. It describes a contextual way to
sell a price.

Checkout requests include the offer revision displayed by the client. Buylla
rejects stale revisions and asks the client to refresh the campaign.

### `offer_phases`

Ordered, temporary introductory terms applied before the base price takes over.

Core data:

- Offer UUID
- Position
- Duration unit: `day` or `billing_period`
- Positive duration count
- Charge type: `fixed` or `percent_off_base`
- Fixed amount and currency, or percentage
- JSON presentation metadata

Examples:

```text
Phase 1: $4.99 for 7 days
Phase 2: 20% off the base price for 2 billing periods
Afterward: base price
```

A free trial is a fixed introductory phase with amount zero. A paid trial is a
fixed phase with an explicit amount.

For nonstandard durations such as three or seven days, the charge is always
explicit. Metadata may explain that amount as "50% off," but metadata never
determines what is charged.

Publishing validates that the selected provider can execute the entire phase
schedule.

### `campaigns`

A client-retrievable monetization experience.

Examples:

- Google 320 Advertisement
- Default Pricing Page
- Product Launch

Core data:

- Internal UUID
- Company UUID and mode
- Stable company-scoped code
- Name
- Integer revision
- Status: `draft`, `published`, or `archived`
- Optional availability start and end
- JSON attribution and presentation metadata

`Campaign` is preferred over `Offer Set` in v1 because the object carries
marketing identity, timing, attribution, and conversion meaning. A reusable
offer-set abstraction is deferred until multiple campaigns need to share an
identical collection.

### `campaign_entries`

The main offers initially presented by a campaign.

Core data:

- Campaign UUID
- Offer UUID
- Display position
- JSON membership metadata

A campaign may have multiple entries, such as Pro, Premium, and Express.

### `campaign_offer_links`

Contextual alternatives available within a campaign.

Core data:

- Campaign UUID
- Nullable source offer UUID
- Target offer UUID
- Company-defined relationship type
- Display position
- JSON relationship metadata

Examples:

```text
Pro standard -> Pro recovery        type=recovery
Pro standard -> Pro special         type=long_checkout
null         -> General recovery    type=abandonment
```

A null source means the target is campaign-wide. A non-null source means the
target is associated with a particular entry offer.

Buylla returns relationship data but never interprets its behavior. The client
decides what `recovery`, `abandonment`, `long_checkout`, or a custom value means.

For v1, a non-null source must be one of the campaign's entry offers. Deeper
offer-to-offer funnels are deferred until a real use case requires them.

## Test and Live Modes

Catalog and operational data are mode-scoped from the beginning.

Test-to-live promotion copies:

- Products
- Prices
- Offers and phases
- Campaigns
- Campaign entries and links

Promotion never copies:

- Customers
- API keys
- Provider connections
- Checkouts
- Purchases
- Subscriptions
- Provider events

Promotion is transactional and idempotent. Source-to-live mappings are recorded
in `catalog_promotions` and `catalog_promotion_items`. Re-promotion updates
stable live identities by code while creating replacement immutable prices when
financial terms change.

The basic vertical slice operates only in test mode. Live promotion is part of
the complete v1.

## Checkout Data

### `provider_connections`

One provider connection per company and mode in v1. The first supported provider
is Stripe.

Provider credentials are stored in a managed secret system or with envelope
encryption. They are never returned through the API or written to logs.

### `checkouts`

A pending or completed attempt to purchase one or more offers.

Core data:

- Internal UUID
- Company UUID and mode
- Customer UUID
- Campaign UUID and revision
- Status
- Currency and calculated totals
- Provider connection and provider checkout ID
- Expiration time
- Client metadata

Checkout invariants:

- Every quantity is a positive integer.
- Every item uses the same currency.
- Recurring items share the same billing period unit and count.
- One-time items may accompany the compatible recurring group.
- Introductory phases apply only to recurring offers in v1.
- A one-time promotional amount uses a separate immutable one-time price.

### `checkout_items`

Immutable snapshots of selected offer terms.

Each snapshot retains:

- Product, price, and offer identifiers and codes
- Product name
- Offer and campaign revisions
- Unit amount and currency
- Billing period
- Introductory phases
- Quantity
- Presentation metadata shown to the customer

Snapshots preserve what the customer accepted even when the catalog changes.
Catalog references remain for traceability, but historical calculations use the
snapshot.

### `idempotency_keys`

Client-generated random UUIDs scoped by company, mode, and operation.

The stored record includes:

- Key
- Canonical request fingerprint
- Processing status
- Checkout UUID
- Stored response
- Creation and expiration timestamps

Same key and same fingerprint returns the original response. Same key and a
different fingerprint returns a conflict.

### `provider_events`

Verified inbound provider webhook events.

The provider connection and provider event ID form a unique pair. Events retain
the verified payload for auditing and retry-safe asynchronous processing.

### `purchases`

Normalized record of a completed one-time or initial purchase. The payment
provider remains authoritative for financial state.

### `subscriptions`

Normalized mirror of the provider subscription used by client lookup APIs. It
does not calculate renewals, invoices, proration, or retries.

### Client webhook outbox

Outbound client webhook records are written in the same transaction as purchase
or subscription state changes. A worker signs and retries delivery afterward.

## First Vertical Slice

Build the smallest complete test-mode flow:

1. Create a user, company, and owner membership.
2. Configure one Stripe test connection.
3. Create one product.
4. Create one recurring price.
5. Create one standard offer.
6. Create one campaign containing that offer as an entry.
7. Retrieve the resolved campaign.
8. Create a customer from an external customer ID.
9. Create an idempotent checkout.
10. Redirect to Stripe-hosted Checkout.
11. Verify and store Stripe's webhook.
12. Mark the checkout complete and create purchase/subscription mirrors.
13. Retrieve the completed checkout from the client API.

Recovery offers, live promotion, outbound webhooks, and multiple team roles are
added after this path succeeds.

## Explicitly Deferred

- Buylla-owned invoices and renewal scheduling
- Proration, dunning, account credits, and usage billing
- Tax calculation
- Refund and dispute accounting
- Multiple implemented provider adapters
- Browser-safe publishable keys
- Entitlement and fulfillment management
- Campaign automation and conversion experiments
- Deep or cyclic offer graphs
- Reusable offer sets
- Physical inventory, shipping, and fulfillment

## Manual Modeling Exercise

Before writing the migration, create example rows on paper or in a scratch file
for:

```text
Company: Acme AI

Product:
  pro

Prices:
  pro-monthly at $19.99/month
  pro-yearly at $199.99/year

Offers:
  pro-standard
  pro-recovery with $4.99 for 7 days,
    then 20% off for 2 billing periods

Campaign:
  google-320

Entry:
  pro-standard

Link:
  pro-standard -> pro-recovery, type=recovery
```

For every field, ask:

1. Is this identity, financial truth, presentation, or integration data?
2. Who owns it?
3. Can it change?
4. If it changes, should historical purchases change?
5. What must be unique?
6. What must never be null?
7. What will the application query by?

Only after those answers are clear should the example become SQL.
