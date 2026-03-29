package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
)

func ProfileHandler(w http.ResponseWriter, r *http.Request) {
	profile, err := repository.GetProfile()
	if err != nil {
		http.Error(w, "erro ao buscar profile", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profile)
}
