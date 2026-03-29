package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func AdminUpdateProfileHandler(w http.ResponseWriter, r *http.Request) {
	var p model.Profile
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	updated, err := repository.UpdateProfile(r.Context(), p)
	if err != nil {
		http.Error(w, "erro ao atualizar perfil", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updated)
}
