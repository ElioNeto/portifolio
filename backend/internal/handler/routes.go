package handler

import "net/http"

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", HealthHandler)
	mux.HandleFunc("GET /api/projects", ProjectsHandler)
	mux.HandleFunc("GET /api/skills", SkillsHandler)
	mux.HandleFunc("GET /api/profile", ProfileHandler)
}
