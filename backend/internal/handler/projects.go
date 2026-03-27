package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
)

func ProjectsHandler(w http.ResponseWriter, r *http.Request) {
	projects := repository.GetProjects()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(projects)
}
