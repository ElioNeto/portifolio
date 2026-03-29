package handler

import (
	"encoding/json"
	"net/http"
	"os"
	"time"

	"github.com/ElioNeto/portifolio/backend/internal/auth"
	"golang.org/x/crypto/bcrypt"
)

const refreshCookie = "refresh_token"

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	ip := r.RemoteAddr
	ctx := r.Context()

	if err := auth.CheckRateLimit(ctx, ip); err != nil {
		http.Error(w, err.Error(), http.StatusTooManyRequests)
		return
	}

	var body struct {
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}

	hashed := os.Getenv("ADMIN_PASSWORD_HASH")
	if err := bcrypt.CompareHashAndPassword([]byte(hashed), []byte(body.Password)); err != nil {
		auth.RecordAttempt(ctx, ip)
		http.Error(w, "credenciais inválidas", http.StatusUnauthorized)
		return
	}

	auth.ClearAttempts(ctx, ip)

	accessToken, err := auth.GenerateAccessToken()
	if err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}

	refreshRaw, err := auth.GenerateRefreshToken()
	if err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}
	if err := auth.StoreRefreshToken(ctx, refreshRaw); err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     refreshCookie,
		Value:    refreshRaw,
		Path:     "/api/auth",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
		Expires:  time.Now().Add(7 * 24 * time.Hour),
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"access_token": accessToken})
}

func RefreshHandler(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie(refreshCookie)
	if err != nil {
		http.Error(w, "sem refresh token", http.StatusUnauthorized)
		return
	}

	newRaw, err := auth.ValidateAndRotateRefreshToken(r.Context(), cookie.Value)
	if err != nil {
		http.Error(w, "refresh token inválido", http.StatusUnauthorized)
		return
	}

	accessToken, err := auth.GenerateAccessToken()
	if err != nil {
		http.Error(w, "erro interno", http.StatusInternalServerError)
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     refreshCookie,
		Value:    newRaw,
		Path:     "/api/auth",
		HttpOnly: true,
		Secure:   true,
		SameSite: http.SameSiteStrictMode,
		Expires:  time.Now().Add(7 * 24 * time.Hour),
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"access_token": accessToken})
}

func LogoutHandler(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie(refreshCookie)
	if err == nil {
		auth.RevokeRefreshToken(r.Context(), cookie.Value)
	}
	http.SetCookie(w, &http.Cookie{
		Name:     refreshCookie,
		Path:     "/api/auth",
		HttpOnly: true,
		Secure:   true,
		MaxAge:   -1,
	})
	w.WriteHeader(http.StatusNoContent)
}

func SendOTPHandler(w http.ResponseWriter, r *http.Request) {
	purpose := r.URL.Query().Get("purpose")
	if purpose == "" {
		http.Error(w, "purpose obrigatório", http.StatusBadRequest)
		return
	}
	if err := auth.SendOTP(r.Context(), purpose); err != nil {
		http.Error(w, "falha ao enviar OTP", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func ValidateOTPHandler(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Purpose string `json:"purpose"`
		Code    string `json:"code"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	if err := auth.ValidateOTP(r.Context(), body.Purpose, body.Code); err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
