import { Component, inject, OnInit, signal } from '@angular/core';
import { AsyncPipe } from '@angular/common';
import { PortfolioService } from '../../core/services/portfolio.service';
import { Profile } from '../../core/models/portfolio.models';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [AsyncPipe],
  templateUrl: './hero.component.html',
  styleUrls: ['./hero.component.scss']
})
export class HeroComponent implements OnInit {
  private readonly portfolioService = inject(PortfolioService);
  profile = signal<Profile | null>(null);

  ngOnInit(): void {
    this.portfolioService.getProfile().subscribe((p) => this.profile.set(p));
  }
}
