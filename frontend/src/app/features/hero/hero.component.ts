import { Component, inject, OnInit, signal } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Profile } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [AsyncPipe],
  template: `
    <section id="hero" class="hero">
      <div class="container">
        @if (profile(); as p) {
          <span class="badge" i18n="@@hero.badge">Available for projects</span>
          <h1>{{ p.name }}</h1>
          <p class="role">{{ p.role }}</p>
          <p class="location">📍 {{ p.location }}</p>
          <div class="cta">
            <a href="#projects" class="btn-primary" i18n="@@hero.cta.projects">View Projects</a>
            <a href="#contact" class="btn-secondary" i18n="@@hero.cta.contact">Get in Touch</a>
          </div>
        } @else {
          <div class="skeleton-hero"></div>
        }
      </div>
    </section>
  `,
  styles: [`
    .hero {
      min-height: 100vh;
      display: flex;
      align-items: center;
      background: radial-gradient(ellipse at 30% 50%, rgba(0,212,170,0.08) 0%, transparent 60%);
    }
    h1 { font-size: clamp(2.5rem, 6vw, 4.5rem); margin: 1rem 0 0.5rem; }
    .role { font-size: clamp(1rem, 2.5vw, 1.5rem); color: var(--color-primary); font-weight: 500; margin-bottom: 0.5rem; }
    .location { color: var(--color-text-muted); margin-bottom: 2rem; }
    .cta { display: flex; gap: 1rem; flex-wrap: wrap; }
    .btn-primary {
      padding: 0.875rem 2rem;
      background: var(--color-primary);
      color: #0a0e1a;
      border-radius: var(--radius);
      font-weight: 700;
      transition: opacity var(--transition);
    }
    .btn-primary:hover { opacity: 0.85; }
    .btn-secondary {
      padding: 0.875rem 2rem;
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text);
      font-weight: 600;
      transition: border-color var(--transition);
    }
    .btn-secondary:hover { border-color: var(--color-primary); }
    .skeleton-hero { height: 300px; background: var(--color-surface); border-radius: var(--radius); }
  `]
})
export class HeroComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);
  profile = signal<Profile | null>(null);

  ngOnInit(): void {
    this.portfolioService.getProfile().subscribe((p) => this.profile.set(p));
  }
}
