import { Component, inject, OnInit, signal } from '@angular/core';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Profile } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-about',
  standalone: true,
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.scss']
})
export class AboutComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);

  profile = signal<Profile | null>(null);
  bio = signal<string>('Engenheiro e Arquiteto de Software especializado em desenvolvimento de softwares escaláveis.');

  readonly stats = [
    { value: '8+', label: 'Anos de Experiência' },
    { value: '15+', label: 'Projetos Entregues' },
    { value: '3', label: 'Linguagens' },
  ];

  readonly services = [
    { icon: '📧', label: 'Automação para Email e WhatsApp' },
    { icon: '🌐', label: 'Sites e Sistemas' },
    { icon: '⚙️', label: 'Automações Diversas' },
    { icon: '💡', label: 'Consultoria' },
  ];

  ngOnInit(): void {
    this.portfolioService.getProfile().subscribe((p) => {
      this.profile.set(p);
      if (p.bio && (p.bio['pt'] || p.bio['en'])) {
        this.bio.set(p.bio['pt'] ?? p.bio['en']);
      }
    });
  }
}
