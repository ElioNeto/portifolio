package repository

import (
	"context"

	"github.com/ElioNeto/portifolio/backend/internal/database"
	"github.com/ElioNeto/portifolio/backend/internal/model"
)

func GetProfile() (*model.Profile, error) {
	row := database.Pool.QueryRow(context.Background(), `
		SELECT name, role, location, email, github, blog, bio_pt, bio_en, bio_es
		FROM profile LIMIT 1
	`)

	var p model.Profile
	var bioPT, bioEN, bioES string
	err := row.Scan(&p.Name, &p.Role, &p.Location, &p.Email, &p.GitHub, &p.Blog, &bioPT, &bioEN, &bioES)
	if err != nil {
		return nil, err
	}
	p.Bio = map[string]string{"pt": bioPT, "en": bioEN, "es": bioES}
	return &p, nil
}

func GetProjectsFromDB() ([]model.Project, error) {
	rows, err := database.Pool.Query(context.Background(), `
		SELECT id, title, desc_pt, desc_en, desc_es, tech, github_url, COALESCE(live_url,''), featured
		FROM projects ORDER BY featured DESC, id ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var projects []model.Project
	for rows.Next() {
		var p model.Project
		var descPT, descEN, descES string
		err := rows.Scan(&p.ID, &p.Title, &descPT, &descEN, &descES, &p.Tech, &p.GitHub, &p.Live, &p.Featured)
		if err != nil {
			return nil, err
		}
		p.Description = map[string]string{"pt": descPT, "en": descEN, "es": descES}
		projects = append(projects, p)
	}
	return projects, nil
}
