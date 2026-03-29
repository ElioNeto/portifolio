package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/ElioNeto/portifolio/backend/internal/database"
)

const refreshTokenTTL = 7 * 24 * time.Hour

func GenerateRefreshToken() (raw string, err error) {
	b := make([]byte, 32)
	if _, err = rand.Read(b); err != nil {
		return
	}
	raw = hex.EncodeToString(b)
	return
}

func hashToken(raw string) string {
	h := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(h[:])
}

func StoreRefreshToken(ctx context.Context, raw string) error {
	hash := hashToken(raw)
	expires := time.Now().Add(refreshTokenTTL)
	_, err := database.Pool.Exec(ctx,
		`INSERT INTO refresh_tokens (token_hash, expires_at) VALUES ($1, $2)`,
		hash, expires)
	return err
}

func ValidateAndRotateRefreshToken(ctx context.Context, raw string) (newRaw string, err error) {
	hash := hashToken(raw)
	tag, err := database.Pool.Exec(ctx,
		`UPDATE refresh_tokens SET revoked = true
		 WHERE token_hash = $1 AND revoked = false AND expires_at > now()`,
		hash)
	if err != nil {
		return
	}
	if tag.RowsAffected() == 0 {
		err = ErrInvalidToken
		return
	}
	newRaw, err = GenerateRefreshToken()
	if err != nil {
		return
	}
	err = StoreRefreshToken(ctx, newRaw)
	return
}

func RevokeRefreshToken(ctx context.Context, raw string) error {
	hash := hashToken(raw)
	_, err := database.Pool.Exec(ctx,
		`UPDATE refresh_tokens SET revoked = true WHERE token_hash = $1`, hash)
	return err
}
