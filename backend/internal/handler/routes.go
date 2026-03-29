package handler

import (
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/middleware"
)

func RegisterRoutes(mux *http.ServeMux) {
	// Public
	mux.HandleFunc("GET /health", HealthHandler)
	mux.HandleFunc("GET /api/projects", ProjectsHandler)
	mux.HandleFunc("GET /api/skills", SkillsHandler)
	mux.HandleFunc("GET /api/profile", ProfileHandler)

	// Auth
	mux.HandleFunc("POST /api/auth/login", LoginHandler)
	mux.HandleFunc("POST /api/auth/refresh", RefreshHandler)
	mux.HandleFunc("POST /api/auth/logout", LogoutHandler)
	mux.HandleFunc("POST /api/auth/otp/send", middleware.RequireJWT(http.HandlerFunc(SendOTPHandler)).ServeHTTP)
	mux.HandleFunc("POST /api/auth/otp/validate", middleware.RequireJWT(http.HandlerFunc(ValidateOTPHandler)).ServeHTTP)

	// Admin — protected
	admin := http.NewServeMux()
	admin.HandleFunc("POST /api/admin/projects", AdminCreateProjectHandler)
	admin.HandleFunc("PUT /api/admin/projects/{id}", AdminUpdateProjectHandler)
	admin.HandleFunc("DELETE /api/admin/projects/{id}", AdminDeleteProjectHandler)
	admin.HandleFunc("POST /api/admin/skills", AdminCreateSkillHandler)
	admin.HandleFunc("PUT /api/admin/skills/{id}", AdminUpdateSkillHandler)
	admin.HandleFunc("DELETE /api/admin/skills/{id}", AdminDeleteSkillHandler)
	admin.HandleFunc("PUT /api/admin/profile", AdminUpdateProfileHandler)

	mux.Handle("/api/admin/", middleware.RequireJWT(admin))
}
