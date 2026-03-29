package repository

import (
	"context"

	"github.com/ElioNeto/portifolio/backend/internal/database"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func GetSkills() ([]model.Skill, error) {
	rows, err := database.Pool.Query(context.Background(),
		`SELECT id, name, level, category FROM skills ORDER BY category, level DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var skills []model.Skill
	for rows.Next() {
		var s model.Skill
		if err := rows.Scan(&s.ID, &s.Name, &s.Level, &s.Category); err != nil {
			return nil, err
		}
		skills = append(skills, s)
	}
	return skills, nil
}
