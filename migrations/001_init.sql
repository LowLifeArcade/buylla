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
            status in ('archived', 'draft', 'active')
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
            status in ('archived', 'draft', 'active')
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

CREATE TABLE offers(
    id uuid DEFAULT uuidv7() PRIMARY KEY,
    price_id uuid not null REFERENCES prices(id),
    code text not null,
    revision integer not null default 1
        check (revision > 0),
    status text not null default 'draft'
        check (
            status in ('draft', 'active', 'archived')
        ),
    available_from timestamptz,
    available_until timestamptz,
    metadata jsonb not null default '{}'::jsonb
        check (
            jsonb_typeof(metadata) = 'object'
        ),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (code, price_id),
    check (
        available_from is null
        or available_until is null
        or available_until > available_from
    )
);

CREATE TABLE offer_phases(
    offer_id uuid not null REFERENCES offers(id),
    position integer not null
        check (
            position > 0
        ),
    duration_unit text not null
        check (
            duration_unit in ('day', 'billing_period')
        ),
    duration_count integer not null
        check (
            duration_count > 0
        ),
    charge_type text not null
        check (
            charge_type in ('fixed', 'percent_off_base')
        ),
    fixed_amount bigint
        check (
            fixed_amount >= 0
        ),
    currency text
        check (
            currency = upper(currency)
            AND char_length(currency) = 3
        ),
    percent_off numeric(5, 2)
        check (
            percent_off > 0
            and percent_off <= 100
        ),
    metadata jsonb not null default '{}'::jsonb
        check (
            jsonb_typeof(metadata) = 'object'
        ),
    PRIMARY KEY (offer_id, position),
    CHECK (
        (
            charge_type = 'fixed'
            and fixed_amount is not null
            and currency is not null
            and percent_off is null
        )
        OR
        (
            charge_type = 'percent_off_base'
            and fixed_amount is null
            and currency is null
            and percent_off is not null
        )
    ),
    CHECK (
        duration_unit <> 'day'
        OR charge_type = 'fixed'
    )
);
