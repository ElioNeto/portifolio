package model

type Project struct {
	ID          int               `json:"id"`
	Title       string            `json:"title"`
	Description map[string]string `json:"description"`
	Tech        []string          `json:"tech"`
	GitHub      string            `json:"github"`
	Live        string            `json:"live,omitempty"`
	Featured    bool              `json:"featured"`
}
