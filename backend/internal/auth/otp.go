package auth

import (
	"context"
	"crypto/rand"
	"fmt"
	"math/big"
	"net/smtp"
	"os"
	"time"

	"github.com/ElioNeto/portifolio/backend/internal/database"
)

const otpTTL = 10 * time.Minute

func generateOTPCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func SendOTP(ctx context.Context, purpose string) error {
	code, err := generateOTPCode()
	if err != nil {
		return err
	}

	codeHash := hashToken(code)
	expires := time.Now().Add(otpTTL)

	// invalidate previous unused OTPs for same purpose
	_, _ = database.Pool.Exec(ctx,
		`UPDATE otp_codes SET used = true WHERE purpose = $1 AND used = false`, purpose)

	_, err = database.Pool.Exec(ctx,
		`INSERT INTO otp_codes (code_hash, purpose, expires_at) VALUES ($1, $2, $3)`,
		codeHash, purpose, expires)
	if err != nil {
		return err
	}

	return sendEmail(
		fmt.Sprintf("[Admin] Código de confirmação: %s", purpose),
		fmt.Sprintf("Seu código OTP é: %s\n\nVálido por 10 minutos.", code),
	)
}

func ValidateOTP(ctx context.Context, purpose, code string) error {
	codeHash := hashToken(code)
	tag, err := database.Pool.Exec(ctx,
		`UPDATE otp_codes SET used = true
		 WHERE code_hash = $1 AND purpose = $2
		   AND used = false AND expires_at > now()`,
		codeHash, purpose)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return fmt.Errorf("código inválido ou expirado")
	}
	return nil
}

func sendEmail(subject, body string) error {
	host := os.Getenv("SMTP_HOST")
	port := os.Getenv("SMTP_PORT")
	user := os.Getenv("SMTP_USER")
	pass := os.Getenv("SMTP_PASS")
	to := os.Getenv("ADMIN_EMAIL")

	auth := smtp.PlainAuth("", user, pass, host)
	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\n\r\n%s",
		user, to, subject, body)
	return smtp.SendMail(host+":"+port, auth, user, []string{to}, []byte(msg))
}
