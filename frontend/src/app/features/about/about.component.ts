import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Profile } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-about',
  standalone: true,
  template: `
    <section id="about" class="container">
      <h2>Sobre Mim</h2>
      @if (profile(); as p) {
        <div class="about-grid">
          <div class="about-text">
            <p>{{ p.bio['pt'] }}</p>
            <div class="stats">
              <div class="stat">
                <span class="stat-value">{{ p.stat_years }}</span>
                <span class="stat-label">Anos de Experiência</span>
              </div>
              <div class="stat">
                <span class="stat-value">{{ p.stat_projects }}</span>
                <span class="stat-label">Projetos Entregues</span>
              </div>
              <div class="stat">
                <span class="stat-value">{{ p.stat_langs }}</span>
                <span class="stat-label">Linguagens</span>
              </div>
            </div>
          </div>
        </div>
      }
    </section>
  `,
  styles: [`
    .about-grid { display: grid; gap: 2rem; }
    .about-text p { color: var(--color-text-muted); font-size: 1.1rem; line-height: 1.8; margin-bottom: 2rem; }
    .stats { display: flex; gap: 2.5rem; flex-wrap: wrap; }
    .stat { display: flex; flex-direction: column; }
    .stat-value { font-size: 2rem; font-weight: 800; color: var(--color-primary); }
    .stat-label { font-size: 0.85rem; color: var(--color-text-muted); }
  `]
})
export class AboutComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);
  profile = signal<Profile | null>(null);

  ngOnInit(): void {
    this.portfolioService.getProfile().subscribe((p) => this.profile.set(p));
  }
}
