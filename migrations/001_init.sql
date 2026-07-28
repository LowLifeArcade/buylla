CREATE TABLE companies(
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    name text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    code text not null UNIQUE
);

CREATE TABLE company_environments (
    id uuid DEFAULT uuidv7() PRIMARY KEY,
    company_id uuid NOT NULL REFERENCES companies(id),
    mode text NOT NULL
        CHECK (mode IN ('test', 'live')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (company_id, mode)
);

CREATE TABLE products(
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    name text not null,
    code text not null,
    description text,
    metadata jsonb not null default '{}'::jsonb
        CHECK (
            jsonb_typeof(metadata) = 'object'
        ),
    environment_id uuid not null
        references company_environments(id),
    status text not null default 'draft'
        CHECK (
            status in ('archived', 'draft', 'published')
        ),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    UNIQUE (code, environment_id)
);

CREATE TABLE prices(
    id UUID DEFAULT uuidv7() PRIMARY KEY,
    name text not null,
    code text not null,
    unit_amount bigint not null
        CHECK (
            unit_amount >= 0
        ),
    currency text not null
        CHECK (
            currency = upper(currency)
            and char_length(currency) = 3
        ),
    billing_type text not null
        CHECK (
            billing_type in ('one_time', 'recurring')
        ),
    billing_period_unit text
        CHECK (
            billing_period_unit in ('day', 'week', 'month', 'year')
        ),
    billing_period_count integer
        CHECK (billing_period_count > 0),
    product_id uuid NOT NULL REFERENCES products(id),
    status text not null default 'draft'
        CHECK (
            status in ('archived', 'draft', 'published')
        ),
    metadata jsonb not null default '{}'::jsonb
        CHECK (
            jsonb_typeof(metadata) = 'object'
        ),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    UNIQUE (code, product_id),
    CHECK (
        (
            billing_type = 'one_time'
            and billing_period_unit is null
            and billing_period_count is null
        )
        OR
        (
            billing_type = 'recurring'
            and billing_period_unit is not null
            and billing_period_count is not null
        )
    )
);
