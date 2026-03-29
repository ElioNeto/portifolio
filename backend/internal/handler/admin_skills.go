package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/ElioNeto/portifolio/backend/internal/repository"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func AdminCreateSkillHandler(w http.ResponseWriter, r *http.Request) {
	var s model.Skill
	if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	created, err := repository.CreateSkill(r.Context(), s)
	if err != nil {
		http.Error(w, "erro ao criar skill", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(created)
}

func AdminUpdateSkillHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "id inválido", http.StatusBadRequest)
		return
	}
	var s model.Skill
	if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
		http.Error(w, "body inválido", http.StatusBadRequest)
		return
	}
	s.ID = id
	updated, err := repository.UpdateSkill(r.Context(), s)
	if err != nil {
		http.Error(w, "erro ao atualizar skill", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updated)
}

func AdminDeleteSkillHandler(w http.ResponseWriter, r *http.Request) {
	idStr := r.PathValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "id inválido", http.StatusBadRequest)
		return
	}
	if err := repository.DeleteSkill(r.Context(), id); err != nil {
		http.Error(w, "erro ao deletar skill", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
