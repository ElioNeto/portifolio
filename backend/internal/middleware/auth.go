package middleware

import (
	"net/http"
	"strings"

	"github.com/ElioNeto/portifolio/backend/internal/auth"
)

func RequireJWT(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			http.Error(w, "não autorizado", http.StatusUnauthorized)
			return
		}
		tokenStr := strings.TrimPrefix(header, "Bearer ")
		if err := auth.ValidateAccessToken(tokenStr); err != nil {
			http.Error(w, "token inválido", http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}
