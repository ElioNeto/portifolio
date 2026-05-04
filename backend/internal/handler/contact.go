package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/smtp"
	"os"
	"strings"
)

type contactRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Message string `json:"message"`
}

func ContactHandler(w http.ResponseWriter, r *http.Request) {
	var req contactRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "payload inválido", http.StatusBadRequest)
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.TrimSpace(req.Email)
	req.Message = strings.TrimSpace(req.Message)

	if req.Name == "" || req.Email == "" || req.Message == "" {
		http.Error(w, "campos obrigatórios ausentes", http.StatusBadRequest)
		return
	}

	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")
	smtpTo   := os.Getenv("SMTP_TO")

	if smtpHost == "" || smtpUser == "" || smtpPass == "" || smtpTo == "" {
		http.Error(w, "servidor de email não configurado", http.StatusInternalServerError)
		return
	}

	if smtpPort == "" {
		smtpPort = "587"
	}

	subject := fmt.Sprintf("[Portfólio] Mensagem de %s", req.Name)
	body := fmt.Sprintf(
		"Nome: %s\nEmail: %s\n\nMensagem:\n%s",
		req.Name, req.Email, req.Message,
	)

	msg := []byte(fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s",
		smtpUser, smtpTo, subject, body,
	))

	auth := smtp.PlainAuth("", smtpUser, smtpPass, smtpHost)
	if err := smtp.SendMail(smtpHost+":"+smtpPort, auth, smtpUser, []string{smtpTo}, msg); err != nil {
		http.Error(w, "falha ao enviar email", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
