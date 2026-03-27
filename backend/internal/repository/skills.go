package repository

import "github.com/ElioNeto/portifolio/backend/internal/model"

func GetSkills() []model.Skill {
	return []model.Skill{
		{Name: "Java", Level: 95, Category: "backend"},
		{Name: "Go", Level: 88, Category: "backend"},
		{Name: "Microservices", Level: 92, Category: "architecture"},
		{Name: "Cloud-Native", Level: 88, Category: "architecture"},
		{Name: "Mainframe / COBOL", Level: 85, Category: "legacy"},
		{Name: "Docker", Level: 90, Category: "devops"},
		{Name: "PostgreSQL", Level: 85, Category: "database"},
		{Name: "Angular", Level: 80, Category: "frontend"},
		{Name: "Railway", Level: 88, Category: "devops"},
		{Name: "Clean Architecture", Level: 92, Category: "architecture"},
	}
}
