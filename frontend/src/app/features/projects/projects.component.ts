import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Project } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-projects',
  standalone: true,
  templateUrl: './projects.component.html',
  styleUrls: ['./projects.component.scss']
})
export class ProjectsComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);

  projects = signal<Project[]>([]);

  ngOnInit(): void {
    this.portfolioService.getProjects().subscribe((p) => this.projects.set(p));
  }

  getDescription(project: Project): string {
    return project.description['pt'] ?? project.description['en'];
  }
}
