import { Component, inject } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <div class="admin-layout">
      <nav class="sidebar">
        <div class="brand">Admin</div>
        <a routerLink="projects" routerLinkActive="active">Projetos</a>
        <a routerLink="skills" routerLinkActive="active">Skills</a>
        <a routerLink="profile" routerLinkActive="active">Perfil</a>
        <button class="logout" (click)="logout()">Sair</button>
      </nav>
      <main class="content">
        <router-outlet />
      </main>
    </div>
  `,
  styles: [`
    .admin-layout { display: flex; min-height: 100vh; background: #0a0a0a; color: #fff; }
    .sidebar {
      width: 200px;
      background: #111;
      border-right: 1px solid #222;
      padding: 2rem 1rem;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    .brand { font-weight: 700; font-size: 1.2rem; margin-bottom: 1.5rem; color: #6366f1; }
    a {
      color: #aaa;
      text-decoration: none;
      padding: 0.6rem 0.75rem;
      border-radius: 8px;
      transition: all 0.2s;
    }
    a:hover, a.active { background: #1e1e2e; color: #fff; }
    .logout {
      margin-top: auto;
      background: none;
      border: 1px solid #333;
      color: #aaa;
      padding: 0.6rem;
      border-radius: 8px;
      cursor: pointer;
    }
    .logout:hover { border-color: #f87171; color: #f87171; }
    .content { flex: 1; padding: 2rem; overflow-y: auto; }
  `],
})
export class DashboardComponent {
  private readonly auth = inject(AuthService);
  logout() { this.auth.logout(); }
}
