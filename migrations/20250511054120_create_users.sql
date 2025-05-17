-- migrate:up
CREATE TABLE IF NOT EXISTS users (
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, user_id),
    UNIQUE (tenant_id, email)
);

