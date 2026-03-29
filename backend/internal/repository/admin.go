package repository

import (
	"context"

	"github.com/ElioNeto/portifolio/backend/internal/database"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

// ----- Projects -----

func CreateProject(ctx context.Context, p model.Project) (model.Project, error) {
	err := database.Pool.QueryRow(ctx,
		`INSERT INTO projects (title, desc_pt, desc_en, desc_es, tech, github_url, live_url, featured)
		 VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
		p.Title, p.Description["pt"], p.Description["en"], p.Description["es"],
		p.Tech, p.GitHub, p.Live, p.Featured,
	).Scan(&p.ID)
	return p, err
}

func UpdateProject(ctx context.Context, p model.Project) (model.Project, error) {
	_, err := database.Pool.Exec(ctx,
		`UPDATE projects SET title=$1, desc_pt=$2, desc_en=$3, desc_es=$4,
		 tech=$5, github_url=$6, live_url=$7, featured=$8 WHERE id=$9`,
		p.Title, p.Description["pt"], p.Description["en"], p.Description["es"],
		p.Tech, p.GitHub, p.Live, p.Featured, p.ID)
	return p, err
}

func DeleteProject(ctx context.Context, id int) error {
	_, err := database.Pool.Exec(ctx, `DELETE FROM projects WHERE id=$1`, id)
	return err
}

// ----- Skills -----

func CreateSkill(ctx context.Context, s model.Skill) (model.Skill, error) {
	err := database.Pool.QueryRow(ctx,
		`INSERT INTO skills (name, level, category) VALUES ($1,$2,$3) RETURNING id`,
		s.Name, s.Level, s.Category,
	).Scan(&s.ID)
	return s, err
}

func UpdateSkill(ctx context.Context, s model.Skill) (model.Skill, error) {
	_, err := database.Pool.Exec(ctx,
		`UPDATE skills SET name=$1, level=$2, category=$3 WHERE id=$4`,
		s.Name, s.Level, s.Category, s.ID)
	return s, err
}

func DeleteSkill(ctx context.Context, id int) error {
	_, err := database.Pool.Exec(ctx, `DELETE FROM skills WHERE id=$1`, id)
	return err
}

// ----- Profile -----

func UpdateProfile(ctx context.Context, p model.Profile) (model.Profile, error) {
	_, err := database.Pool.Exec(ctx,
		`UPDATE profile SET name=$1, role=$2, location=$3, email=$4,
		 github=$5, blog=$6, bio_pt=$7, bio_en=$8, bio_es=$9`,
		p.Name, p.Role, p.Location, p.Email,
		p.GitHub, p.Blog, p.Bio["pt"], p.Bio["en"], p.Bio["es"])
	return p, err
}
