package handler

import (
	"encoding/json"
	"net/http"

	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func ProfileHandler(w http.ResponseWriter, r *http.Request) {
	profile := model.Profile{
		Name:     "Elio Neto",
		Role:     "Software Engineer & Solutions Architect",
		Location: "Brasil",
		Email:    "netoo.elio@hotmail.com",
		GitHub:   "https://github.com/ElioNeto",
		Blog:     "https://lsm-admin-dev.up.railway.app/",
		Bio: map[string]string{
			"pt": "Engenheiro de Software e Arquiteto de Soluções com 8+ anos em Banking Core, especialista em modernização de Mainframe e arquiteturas Cloud-Native com Java e Go.",
			"en": "Software Engineer & Solutions Architect with 8+ years in Banking Core, specializing in Mainframe Modernization and Cloud-Native architectures with Java and Go.",
			"es": "Ingeniero de Software y Arquitecto de Soluciones con más de 8 años en Banking Core, especialista en modernización de Mainframe y arquitecturas Cloud-Native con Java y Go.",
		},
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profile)
}
