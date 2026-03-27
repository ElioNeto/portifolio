package model

type Profile struct {
	Name     string            `json:"name"`
	Role     string            `json:"role"`
	Location string            `json:"location"`
	Email    string            `json:"email"`
	GitHub   string            `json:"github"`
	Blog     string            `json:"blog"`
	Bio      map[string]string `json:"bio"`
}
