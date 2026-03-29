import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Project } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-projects',
  standalone: true,
  template: `
    <section id="projects" class="container">
      <h2>Projetos</h2>
      <div class="projects-grid">
        @for (project of projects(); track project.id) {
          <article class="project-card">
            @if (project.featured) {
              <span class="badge">Destaque</span>
            }
            <h3>{{ project.title }}</h3>
            <p>{{ project.description['pt'] ?? project.description['en'] }}</p>
            <ul class="tech-list">
              @for (tech of project.tech; track tech) {
                <li>{{ tech }}</li>
              }
            </ul>
            <div class="card-links">
              <a [href]="project.github" target="_blank" rel="noopener">GitHub →</a>
              @if (project.live) {
                <a [href]="project.live" target="_blank" rel="noopener">Ver site →</a>
              }
            </div>
          </article>
        } @empty {
          <p>Nenhum projeto encontrado.</p>
        }
      </div>
    </section>
  `,
  styles: [`
    .projects-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; }
    .project-card {
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      padding: 1.75rem;
      transition: border-color var(--transition), transform var(--transition);
    }
    .project-card:hover { border-color: var(--color-primary); transform: translateY(-4px); }
    .project-card h3 { margin: 0.75rem 0 0.5rem; font-size: 1.2rem; }
    .project-card p { color: var(--color-text-muted); font-size: 0.9rem; margin-bottom: 1rem; }
    .tech-list { display: flex; flex-wrap: wrap; gap: 0.5rem; list-style: none; margin-bottom: 1rem; }
    .tech-list li { font-size: 0.75rem; padding: 0.2rem 0.6rem; background: rgba(0,212,170,0.1); border-radius: 4px; color: var(--color-primary); }
    .card-links { display: flex; gap: 1rem; }
    .card-links a { font-size: 0.875rem; font-weight: 600; }
  `]
})
export class ProjectsComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);

  projects = signal<Project[]>([]);

  ngOnInit(): void {
    this.portfolioService.getProjects().subscribe((p) => this.projects.set(p));
  }
}
