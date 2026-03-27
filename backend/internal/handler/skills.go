package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
)

func SkillsHandler(w http.ResponseWriter, r *http.Request) {
	skills := repository.GetSkills()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(skills)
}
