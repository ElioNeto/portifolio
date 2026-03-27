package repository

import "github.com/ElioNeto/portifolio/backend/internal/model"

func GetProjects() []model.Project {
	return []model.Project{
		{
			ID:    1,
			Title: "MCP DinD Server",
			Description: map[string]string{
				"pt": "Servidor MCP em Go com Docker-in-Docker, PostgreSQL e Clean Architecture. Roda no Railway.",
				"en": "MCP Server in Go with Docker-in-Docker, PostgreSQL and Clean Architecture. Runs on Railway.",
				"es": "Servidor MCP en Go con Docker-in-Docker, PostgreSQL y Clean Architecture. Se ejecuta en Railway.",
			},
			Tech:     []string{"Go", "Docker", "PostgreSQL", "Railway"},
			GitHub:   "https://github.com/ElioNeto/mcp-dind-server",
			Featured: true,
		},
		{
			ID:    2,
			Title: "Portfolio",
			Description: map[string]string{
				"pt": "Portfólio pessoal com Angular 17+ e Go backend, com suporte a múltiplos idiomas.",
				"en": "Personal portfolio with Angular 17+ and Go backend, with multi-language support.",
				"es": "Portafolio personal con Angular 17+ y backend en Go, con soporte multiidioma.",
			},
			Tech:     []string{"Angular", "Go", "Railway", "Docker"},
			GitHub:   "https://github.com/ElioNeto/portifolio",
			Featured: true,
		},
	}
}
