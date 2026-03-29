package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
)

func ProjectsHandler(w http.ResponseWriter, r *http.Request) {
	projects, err := repository.GetProjectsFromDB()
	if err != nil {
		http.Error(w, "erro ao buscar projetos", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(projects)
}
