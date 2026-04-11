import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AdminService } from '../../../core/services/admin.service';
import { PortfolioService } from '../../../core/services/portfolio.service';
import { Profile } from '../../../core/models/portfolio.models';

@Component({
  selector: 'app-profile-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="section">
      <h2>Perfil</h2>
      @if (profile()) {
        <form (ngSubmit)="save()" class="form">
          <label>Nome</label>
          <input [(ngModel)]="profile()!.name" name="name" />
          <label>Cargo</label>
          <input [(ngModel)]="profile()!.role" name="role" />
          <label>Localização</label>
          <input [(ngModel)]="profile()!.location" name="location" />
          <label>Email</label>
          <input [(ngModel)]="profile()!.email" name="email" type="email" />
          <label>GitHub</label>
          <input [(ngModel)]="profile()!.github" name="github" />
          <label>Blog / LinkedIn</label>
          <input [(ngModel)]="profile()!.blog" name="blog" />
          <label>Bio</label>
          <textarea [(ngModel)]="profile()!.bio['pt']" name="bio_pt" rows="4"></textarea>

          <h3 style="margin-top:1rem;margin-bottom:0">Estatísticas</h3>
          <label>Anos de Experiência</label>
          <input [(ngModel)]="profile()!.stat_years" name="stat_years" placeholder="ex: 8+" />
          <label>Projetos Entregues</label>
          <input [(ngModel)]="profile()!.stat_projects" name="stat_projects" placeholder="ex: 15+" />
          <label>Linguagens</label>
          <input [(ngModel)]="profile()!.stat_langs" name="stat_langs" placeholder="ex: 3" />

          <button type="submit" class="btn-primary">Salvar</button>
          @if (saved()) { <span class="ok">✓ Salvo</span> }
        </form>
      }
    </div>
  `,
  styles: [`
    .section { max-width: 640px; }
    h2 { margin-bottom: 1.5rem; }
    h3 { color: #aaa; font-size: 0.9rem; text-transform: uppercase; letter-spacing: 0.05em; }
    .form { display: flex; flex-direction: column; gap: 0.5rem; }
    label { color: #aaa; font-size: 0.8rem; }
    input, textarea { background: #1a1a1a; border: 1px solid #333; color: #fff; padding: 0.6rem; border-radius: 8px; width: 100%; box-sizing: border-box; }
    .btn-primary { background: #6366f1; color: #fff; border: none; padding: 0.6rem 1.5rem; border-radius: 8px; cursor: pointer; margin-top: 0.5rem; align-self: flex-start; }
    .ok { color: #4ade80; font-size: 0.85rem; margin-left: 0.75rem; }
  `],
})
export class ProfileAdminComponent implements OnInit {
  private readonly admin = inject(AdminService);
  private readonly portfolio = inject(PortfolioService);

  profile = signal<Profile | null>(null);
  saved = signal(false);

  ngOnInit() {
    this.portfolio.getProfile().subscribe((p) => this.profile.set(p));
  }

  save() {
    const p = this.profile();
    if (!p) return;
    this.admin.updateProfile(p).subscribe(() => {
      this.saved.set(true);
      setTimeout(() => this.saved.set(false), 2000);
    });
  }
}
