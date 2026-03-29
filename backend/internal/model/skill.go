package model

type Skill struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Level    int    `json:"level"`
	Category string `json:"category"`
}
