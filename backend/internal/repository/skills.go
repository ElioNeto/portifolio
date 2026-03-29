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

func CreateSkill(ctx context.Context, s model.Skill) (model.Skill, error) {
	err := database.Pool.QueryRow(ctx,
		`INSERT INTO skills (name, level, category) VALUES ($1, $2, $3) RETURNING id, name, level, category`,
		s.Name, s.Level, s.Category,
	).Scan(&s.ID, &s.Name, &s.Level, &s.Category)
	return s, err
}

func UpdateSkill(ctx context.Context, s model.Skill) (model.Skill, error) {
	err := database.Pool.QueryRow(ctx,
		`UPDATE skills SET name=$1, level=$2, category=$3 WHERE id=$4 RETURNING id, name, level, category`,
		s.Name, s.Level, s.Category, s.ID,
	).Scan(&s.ID, &s.Name, &s.Level, &s.Category)
	return s, err
}

func DeleteSkill(ctx context.Context, id int) error {
	_, err := database.Pool.Exec(ctx, `DELETE FROM skills WHERE id=$1`, id)
	return err
}
