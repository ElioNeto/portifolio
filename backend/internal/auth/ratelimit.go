package auth

import (
	"context"
	"fmt"
	"time"

	"github.com/ElioNeto/portifolio/backend/internal/database"
)

const (
	maxAttempts  = 5
	window       = 15 * time.Minute
)

func CheckRateLimit(ctx context.Context, ip string) error {
	var count int
	err := database.Pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM login_attempts
		 WHERE ip = $1 AND attempt_at > now() - $2::interval`,
		ip, window.String()).Scan(&count)
	if err != nil {
		return err
	}
	if count >= maxAttempts {
		return fmt.Errorf("muitas tentativas, aguarde 15 minutos")
	}
	return nil
}

func RecordAttempt(ctx context.Context, ip string) {
	database.Pool.Exec(ctx,
		`INSERT INTO login_attempts (ip) VALUES ($1)`, ip)
}

func ClearAttempts(ctx context.Context, ip string) {
	database.Pool.Exec(ctx,
		`DELETE FROM login_attempts WHERE ip = $1`, ip)
}
