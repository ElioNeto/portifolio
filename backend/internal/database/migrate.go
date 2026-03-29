package database

import (
	"context"
	"log"
)

func Migrate() error {
	schema := `
	CREATE TABLE IF NOT EXISTS profile (
		id         SERIAL PRIMARY KEY,
		name       TEXT NOT NULL,
		role       TEXT NOT NULL,
		location   TEXT NOT NULL,
		email      TEXT NOT NULL,
		github     TEXT NOT NULL,
		blog       TEXT NOT NULL,
		bio_pt     TEXT NOT NULL,
		bio_en     TEXT NOT NULL,
		bio_es     TEXT NOT NULL
	);

	CREATE TABLE IF NOT EXISTS projects (
		id          SERIAL PRIMARY KEY,
		title       TEXT NOT NULL,
		desc_pt     TEXT NOT NULL,
		desc_en     TEXT NOT NULL,
		desc_es     TEXT NOT NULL,
		tech        TEXT[] NOT NULL,
		github_url  TEXT NOT NULL,
		live_url    TEXT,
		featured    BOOLEAN NOT NULL DEFAULT false
	);

	CREATE TABLE IF NOT EXISTS skills (
		id       SERIAL PRIMARY KEY,
		name     TEXT NOT NULL,
		level    INT NOT NULL,
		category TEXT NOT NULL
	);

	CREATE TABLE IF NOT EXISTS refresh_tokens (
		id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		token_hash TEXT NOT NULL UNIQUE,
		created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
		expires_at TIMESTAMPTZ NOT NULL,
		revoked    BOOLEAN NOT NULL DEFAULT false
	);

	CREATE TABLE IF NOT EXISTS otp_codes (
		id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
		code_hash  TEXT NOT NULL,
		purpose    TEXT NOT NULL,
		created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
		expires_at TIMESTAMPTZ NOT NULL,
		used       BOOLEAN NOT NULL DEFAULT false
	);

	CREATE TABLE IF NOT EXISTS login_attempts (
		ip         TEXT NOT NULL,
		attempt_at TIMESTAMPTZ NOT NULL DEFAULT now()
	);
	CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_time ON login_attempts(ip, attempt_at);
	`

	_, err := Pool.Exec(context.Background(), schema)
	if err != nil {
		return err
	}
	log.Println("✅ Migrations aplicadas")
	return nil
}
