package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func AdminCreateProjectHandler(w http.ResponseWriter, r *http.Request) {
	var p model.Project
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	created, err := repository.CreateProject(r.Context(), p)
	if err != nil {
		http.Error(w, "erro ao criar projeto", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(created)
}

func AdminUpdateProjectHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "id inválido", http.StatusBadRequest)
		return
	}
	var p model.Project
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	p.ID = id
	updated, err := repository.UpdateProject(r.Context(), p)
	if err != nil {
		http.Error(w, "erro ao atualizar projeto", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updated)
}

func AdminDeleteProjectHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "id inválido", http.StatusBadRequest)
		return
	}
	if err := repository.DeleteProject(r.Context(), id); err != nil {
		http.Error(w, "erro ao deletar projeto", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
