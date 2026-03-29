package main

import (
	"log"
	"net/http"
	"os"

	"github.com/ElioNeto/portifolio/backend/internal/database"
	"github.com/ElioNeto/portifolio/backend/internal/handler"
	"github.com/ElioNeto/portifolio/backend/internal/middleware"
)

func main() {
	if err := database.Connect(); err != nil {
		log.Fatalf("db connect: %v", err)
	}

	mux := http.NewServeMux()
	handler.RegisterRoutes(mux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, middleware.CORS(mux)))
}
