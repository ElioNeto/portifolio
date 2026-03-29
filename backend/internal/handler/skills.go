package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
)

func SkillsHandler(w http.ResponseWriter, r *http.Request) {
	skills, err := repository.GetSkillsFromDB()
	if err != nil {
		http.Error(w, "erro ao buscar skills", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(skills)
}
