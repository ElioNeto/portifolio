package database

import (
	"context"
	"log"
)

func Seed() error {
	ctx := context.Background()

	// Profile
	var count int
	Pool.QueryRow(ctx, "SELECT COUNT(*) FROM profile").Scan(&count)
	if count == 0 {
		_, err := Pool.Exec(ctx, `
			INSERT INTO profile (name, role, location, email, github, blog, bio_pt, bio_en, bio_es)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
			"Elio Neto",
			"Cloud Architect | Data Systems Specialist | Modernization Expert",
			"Araquari, Santa Catarina, Brasil",
			"netoo.elio@hotmail.com",
			"https://github.com/ElioNeto",
			"https://www.linkedin.com/in/elioneto",
			"Arquiteto de software especialista em modernização de sistemas legados e cloud-native. Lidero tecnicamente a migração de fluxos críticos de Mainframe para AWS no Itaú Unibanco, com mais de 15 microsserviços migrados para arquiteturas Serverless. MBA em Gestão de Projetos e Pós-graduação em Ciência de Dados.",
			"Software architect specializing in legacy system modernization and cloud-native solutions. I technically lead the migration of critical Mainframe flows to AWS at Itaú Unibanco, with 15+ microservices migrated to Serverless architectures. MBA in Project Management and postgraduate degree in Data Science.",
			"Arquitecto de software especialista en modernización de sistemas legados y cloud-native. Lidero técnicamente la migración de flujos críticos de Mainframe a AWS en Itaú Unibanco, con más de 15 microservicios migrados a arquitecturas Serverless. MBA en Gestión de Proyectos y posgrado en Ciencia de Datos.",
		)
		if err != nil {
			return err
		}
		log.Println("✅ Seed: profile inserido")
	}

	// Projects
	Pool.QueryRow(ctx, "SELECT COUNT(*) FROM projects").Scan(&count)
	if count == 0 {
		projects := []struct {
			title, descPT, descEN, descES, github, live string
			tech                                        []string
			featured                                    bool
		}{
			{
				title:    "ApexStore",
				descPT:   "Motor de armazenamento Key-Value de alta performance usando arquitetura LSM-Tree com WAL e SSTables, escrito em Rust.",
				descEN:   "High-performance Key-Value storage engine using LSM-Tree architecture with WAL and SSTables, written in Rust.",
				descES:   "Motor de almacenamiento Key-Value de alto rendimiento usando arquitectura LSM-Tree con WAL y SSTables, escrito en Rust.",
				tech:     []string{"Rust", "LSM-Tree", "WAL", "SSTables"},
				github:   "https://github.com/ElioNeto/ApexStore",
				featured: true,
			},
			{
				title:    "enginai",
				descPT:   "Agente de IA que scaffolda projetos e implementa features automaticamente via CLI. Usa Gemini (free) e Ollama (local). Zero custo.",
				descEN:   "AI-powered developer agent that scaffolds projects and implements features automatically via CLI. Uses Gemini (free) and Ollama (local). Zero cost.",
				descES:   "Agente de IA que genera scaffolding de proyectos e implementa features automáticamente vía CLI. Usa Gemini (gratis) y Ollama (local). Costo cero.",
				tech:     []string{"TypeScript", "Node.js", "Gemini", "Ollama", "CLI"},
				github:   "https://github.com/ElioNeto/enginai",
				featured: true,
			},
			{
				title:    "vyx",
				descPT:   "Framework full-stack poliglota de alta performance com orquestrador Go, roteamento por anotação e IPC via Unix Domain Sockets + Apache Arrow.",
				descEN:   "High-performance polyglot full-stack framework with a Go Core Orchestrator, annotation-based routing, and IPC via Unix Domain Sockets + Apache Arrow.",
				descES:   "Framework full-stack políglota de alto rendimiento con orquestrador Go, enrutamiento por anotación e IPC vía Unix Domain Sockets + Apache Arrow.",
				tech:     []string{"Go", "Unix Sockets", "Apache Arrow", "Polyglot"},
				github:   "https://github.com/ElioNeto/vyx",
				featured: true,
			},
			{
				title:    "agregador",
				descPT:   "Agregador automatizado de pesquisa acadêmica com categorização por IA. Busca em 7+ bases (ArXiv, PubMed, SciELO, OpenAlex, DOAJ, etc.) via GitHub Issues.",
				descEN:   "Automated academic research aggregator with AI categorization. Searches 7+ databases (ArXiv, PubMed, SciELO, OpenAlex, DOAJ, etc.) via GitHub Issues.",
				descES:   "Agregador automatizado de investigación académica con categorización IA. Busca en 7+ bases (ArXiv, PubMed, SciELO, OpenAlex, DOAJ, etc.) vía GitHub Issues.",
				tech:     []string{"Python", "AI", "GitHub Actions", "SOLID"},
				github:   "https://github.com/ElioNeto/agregador",
				featured: false,
			},
			{
				title:    "agnostikos",
				descPT:   "Distro Linux focada em desenvolvedores com package manager híbrido escrito em Go.",
				descEN:   "Developer-focused Linux distro with a hybrid package manager written in Go.",
				descES:   "Distro Linux orientada a desarrolladores con gestor de paquetes híbrido escrito en Go.",
				tech:     []string{"Go", "Linux", "Shell"},
				github:   "https://github.com/ElioNeto/agnostikos",
				featured: false,
			},
			{
				title:    "aws-serverless-terraform-template",
				descPT:   "Boilerplate AWS Serverless com Terraform modular para modernização de sistemas legados. Lambda, DynamoDB e API Gateway.",
				descEN:   "Opinionated AWS Serverless boilerplate using modular Terraform for legacy modernization. Lambda, DynamoDB, and API Gateway.",
				descES:   "Boilerplate AWS Serverless con Terraform modular para modernización de sistemas legados. Lambda, DynamoDB y API Gateway.",
				tech:     []string{"Terraform", "AWS Lambda", "DynamoDB", "API Gateway", "IaC"},
				github:   "https://github.com/ElioNeto/aws-serverless-terraform-template",
				featured: true,
			},
			{
				title:    "go-graphql-api-boilerplate",
				descPT:   "Boilerplate production-ready de API GraphQL em Go usando gqlgen, PostgreSQL, JWT auth, princípios SOLID e logging estruturado.",
				descEN:   "Production-ready Go GraphQL API boilerplate using gqlgen, PostgreSQL, JWT auth, SOLID principles, and structured logging.",
				descES:   "Boilerplate production-ready de API GraphQL en Go usando gqlgen, PostgreSQL, JWT auth, principios SOLID y logging estructurado.",
				tech:     []string{"Go", "GraphQL", "PostgreSQL", "JWT", "gqlgen"},
				github:   "https://github.com/ElioNeto/go-graphql-api-boilerplate",
				featured: false,
			},
			{
				title:    "android-webcam",
				descPT:   "Use seu Android como webcam de alta qualidade e baixa latência para reuniões. App Android (Kotlin + Jetpack Compose) + cliente desktop (Go).",
				descEN:   "Use your Android phone as a high-quality, low-latency webcam for meetings. Android app (Kotlin + Jetpack Compose) + desktop client (Go).",
				descES:   "Usa tu Android como webcam de alta calidad y baja latencia para reuniones. App Android (Kotlin + Jetpack Compose) + cliente desktop (Go).",
				tech:     []string{"Kotlin", "Jetpack Compose", "Go", "Android"},
				github:   "https://github.com/ElioNeto/android-webcam",
				featured: false,
			},
			{
				title:    "Portfólio",
				descPT:   "Este portfólio pessoal com frontend Angular 17+ e backend Go, com suporte a múltiplos idiomas e deploy no Railway.",
				descEN:   "This personal portfolio with Angular 17+ frontend and Go backend, with multi-language support and Railway deployment.",
				descES:   "Este portafolio personal con frontend Angular 17+ y backend en Go, con soporte multiidioma y deploy en Railway.",
				tech:     []string{"Angular", "Go", "PostgreSQL", "Railway", "Docker"},
				github:   "https://github.com/ElioNeto/portifolio",
				featured: false,
			},
		}

		for _, p := range projects {
			_, err := Pool.Exec(ctx,
				`INSERT INTO projects (title, desc_pt, desc_en, desc_es, tech, github_url, live_url, featured)
				 VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
				p.title, p.descPT, p.descEN, p.descES, p.tech, p.github, p.live, p.featured,
			)
			if err != nil {
				return err
			}
		}
		log.Println("✅ Seed: projects inseridos")
	}

	// Skills
	Pool.QueryRow(ctx, "SELECT COUNT(*) FROM skills").Scan(&count)
	if count == 0 {
		skills := []struct {
			name, category string
			level          int
		}{
			{"Go", "backend", 92},
			{"Python", "backend", 88},
			{"Node.js", "backend", 85},
			{"Java", "backend", 88},
			{".NET / C#", "backend", 85},
			{"Rust", "backend", 75},
			{"Angular", "frontend", 82},
			{"React", "frontend", 78},
			{"AWS", "cloud", 90},
			{"Terraform", "cloud", 85},
			{"Docker", "devops", 90},
			{"Microservices", "architecture", 92},
			{"Clean Architecture", "architecture", 92},
			{"PostgreSQL", "database", 85},
			{"Ciência de Dados", "data", 80},
			{"Modernização Mainframe", "architecture", 88},
		}

		for _, s := range skills {
			_, err := Pool.Exec(ctx,
				`INSERT INTO skills (name, level, category) VALUES ($1,$2,$3)`,
				s.name, s.level, s.category,
			)
			if err != nil {
				return err
			}
		}
		log.Println("✅ Seed: skills inseridas")
	}

	return nil
}
