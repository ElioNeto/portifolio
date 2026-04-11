import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Skill } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-skills',
  standalone: true,
  templateUrl: './skills.component.html',
  styleUrls: ['./skills.component.scss']
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
