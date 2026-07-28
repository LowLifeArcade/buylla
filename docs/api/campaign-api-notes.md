# Campaign API Notes

## Goal

The client-facing campaign endpoint should be exceptionally easy to integrate.
A client can render its initial product choices and immediate recovery or
special offers from one response.

The relational database remains normalized. The application API returns a
denormalized read model.

## Resolved Representation

```http
GET /app/campaigns/:code
```

The default response includes:

- Campaign code, revision, availability, and metadata
- Fully populated entry offers
- Product and base-price data for every entry
- Offer phases
- Fully populated immediate related offers
- Campaign-wide related offers
- Offer and campaign revisions required for checkout

Illustrative shape:

```json
{
  "code": "google-320",
  "revision": 4,
  "name": "Google 320 Advertisement",
  "metadata": {
    "source": "google"
  },
  "entries": [
    {
      "position": 1,
      "offer": {
        "code": "pro-standard",
        "revision": 2,
        "product": {
          "code": "pro",
          "name": "Pro Plan",
          "metadata": {
            "features": ["Feature A", "Feature B"]
          }
        },
        "basePrice": {
          "code": "pro-monthly",
          "amount": 1999,
          "currency": "USD",
          "billingPeriod": {
            "unit": "month",
            "count": 1
          }
        },
        "phases": [],
        "metadata": {
          "headline": "Pro",
          "buttonText": "Choose Pro"
        }
      },
      "relatedOffers": [
        {
          "type": "recovery",
          "metadata": {
            "placement": "exit_modal"
          },
          "offer": {
            "code": "pro-recovery",
            "revision": 1,
            "product": {
              "code": "pro",
              "name": "Pro Plan"
            },
            "basePrice": {
              "code": "pro-monthly",
              "amount": 1999,
              "currency": "USD",
              "billingPeriod": {
                "unit": "month",
                "count": 1
              }
            },
            "phases": [
              {
                "position": 1,
                "duration": {
                  "unit": "day",
                  "count": 7
                },
                "charge": {
                  "type": "fixed",
                  "amount": 499,
                  "currency": "USD"
                },
                "metadata": {
                  "headline": "Try Pro for 7 days"
                }
              }
            ]
          }
        }
      ]
    }
  ],
  "campaignRelatedOffers": [
    {
      "type": "abandonment",
      "offer": {
        "code": "general-recovery",
        "revision": 1
      }
    }
  ]
}
```

The complete response contains every campaign entry, such as Pro, Premium, and
Express.

## Compact Representation

Bandwidth-sensitive clients may request references without expanded catalog
objects:

```http
GET /app/campaigns/:code?view=compact
```

```json
{
  "code": "google-320",
  "revision": 4,
  "entries": [
    {
      "offerCode": "pro-standard",
      "offerRevision": 2,
      "position": 1
    }
  ],
  "links": [
    {
      "sourceOfferCode": "pro-standard",
      "targetOfferCode": "pro-recovery",
      "targetOfferRevision": 1,
      "type": "recovery"
    }
  ]
}
```

Do not add granular field expansion in the initial implementation. Revisit an
`include` mechanism only after measuring real campaign payloads.

## Checkout Contract

Client-visible amounts are not authoritative. Checkout sends identifiers,
revisions, and permitted quantity:

```http
POST /app/checkouts
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000
```

```json
{
  "campaignCode": "google-320",
  "campaignRevision": 4,
  "externalCustomerId": "user-123",
  "items": [
    {
      "offerCode": "pro-recovery",
      "offerRevision": 1,
      "sourceOfferCode": "pro-standard",
      "relationshipType": "recovery",
      "quantity": 1
    },
    {
      "offerCode": "report-one-time",
      "offerRevision": 3,
      "quantity": 1
    }
  ]
}
```

Buylla reloads authoritative catalog data, validates campaign reachability and
revisions, verifies that recurring items share one billing period, calculates
all terms, and creates checkout snapshots. Altering the downloaded campaign JSON
can never alter what Buylla charges.

## Caching

Resolved and compact representations have distinct cache keys and ETags.

Example:

```http
ETag: "campaign-google-320-revision-4-resolved"
Cache-Control: private, max-age=60
```

## Dashboard API

Dashboard endpoints remain normalized because they edit individual resources:

```text
GET /dashboard/products/:id
GET /dashboard/prices/:id
GET /dashboard/offers/:id
GET /dashboard/campaigns/:id
```

Metadata updates use separate permission-protected operations:

```text
PATCH /dashboard/products/:id/metadata
PATCH /dashboard/offers/:id/metadata
PATCH /dashboard/campaigns/:id/metadata
```

## Future Reminder

Default to the developer-friendly resolved campaign document. Preserve the
compact representation for bandwidth-sensitive clients. Consider granular
field expansion only when real payload measurements demonstrate a need.
