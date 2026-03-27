import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Skill } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-skills',
  standalone: true,
  template: `
    <section id="skills" class="container">
      <h2 i18n="@@skills.title">Skills</h2>
      <div class="skills-grid">
        @for (category of categories(); track category) {
          <div class="skill-group">
            <h3>{{ category }}</h3>
            @for (skill of skillsByCategory(category); track skill.name) {
              <div class="skill-item">
                <div class="skill-header">
                  <span>{{ skill.name }}</span>
                  <span class="skill-level">{{ skill.level }}%</span>
                </div>
                <div class="skill-bar">
                  <div class="skill-fill" [style.width.%]="skill.level"></div>
                </div>
              </div>
            }
          </div>
        }
      </div>
    </section>
  `,
  styles: [`
    .skills-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 2rem; }
    .skill-group h3 { color: var(--color-primary); margin-bottom: 1.25rem; text-transform: capitalize; font-size: 0.9rem; letter-spacing: 0.05em; }
    .skill-item { margin-bottom: 1rem; }
    .skill-header { display: flex; justify-content: space-between; margin-bottom: 0.4rem; font-size: 0.875rem; }
    .skill-level { color: var(--color-text-muted); }
    .skill-bar { height: 6px; background: var(--color-border); border-radius: 3px; overflow: hidden; }
    .skill-fill { height: 100%; background: var(--color-primary); border-radius: 3px; transition: width 1s ease; }
  `]
})
export class SkillsComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);
  skills = signal<Skill[]>([]);

  ngOnInit(): void {
    this.portfolioService.getSkills().subscribe((s) => this.skills.set(s));
  }

  categories(): string[] {
    return [...new Set(this.skills().map((s) => s.category))];
  }

  skillsByCategory(category: string): Skill[] {
    return this.skills().filter((s) => s.category === category);
  }
}
