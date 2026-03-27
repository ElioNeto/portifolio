import { Component, inject, OnInit, signal, LOCALE_ID } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Profile } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-about',
  standalone: true,
  template: `
    <section id="about" class="container">
      <h2 i18n="@@about.title">About Me</h2>
      @if (profile(); as p) {
        <div class="about-grid">
          <div class="about-text">
            <p>{{ bio() }}</p>
            <div class="stats">
              @for (stat of stats; track stat.label) {
                <div class="stat">
                  <span class="stat-value">{{ stat.value }}</span>
                  <span class="stat-label">{{ stat.label }}</span>
                </div>
              }
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
  private readonly localeId = inject(LOCALE_ID);

  profile = signal<Profile | null>(null);
  bio = signal<string>('');

  readonly stats = [
    { value: '8+',  label: $localize`:@@about.stat.years:Years of Experience` },
    { value: '15+', label: $localize`:@@about.stat.projects:Projects Delivered` },
    { value: '3',   label: $localize`:@@about.stat.langs:Languages` },
  ];

  ngOnInit(): void {
    this.portfolioService.getProfile().subscribe((p) => {
      this.profile.set(p);
      const lang = this.localeId.split('-')[0];
      this.bio.set(p.bio[lang] ?? p.bio['en']);
    });
  }
}
