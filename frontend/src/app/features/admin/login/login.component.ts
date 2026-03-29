import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <div class="login-wrapper">
      <div class="login-card">
        <h1>Admin</h1>
        <form (ngSubmit)="submit()">
          <label>Senha</label>
          <input
            type="password"
            [(ngModel)]="password"
            name="password"
            autocomplete="current-password"
            required
          />
          <button type="submit" [disabled]="loading()">
            {{ loading() ? 'Entrando...' : 'Entrar' }}
          </button>
        </form>
        @if (error()) {
          <p class="error">{{ error() }}</p>
        }
      </div>
    </div>
  `,
  styles: [`
    .login-wrapper {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #0a0a0a;
    }
    .login-card {
      background: #111;
      border: 1px solid #222;
      border-radius: 12px;
      padding: 2.5rem;
      width: 100%;
      max-width: 380px;
    }
    h1 { color: #fff; margin-bottom: 1.5rem; font-size: 1.5rem; }
    label { color: #aaa; font-size: 0.85rem; display: block; margin-bottom: 0.4rem; }
    input {
      width: 100%;
      padding: 0.75rem;
      background: #1a1a1a;
      border: 1px solid #333;
      border-radius: 8px;
      color: #fff;
      margin-bottom: 1rem;
      box-sizing: border-box;
    }
    button {
      width: 100%;
      padding: 0.75rem;
      background: #6366f1;
      color: #fff;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-weight: 600;
    }
    button:disabled { opacity: 0.6; cursor: not-allowed; }
    .error { color: #f87171; margin-top: 1rem; font-size: 0.875rem; }
  `],
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  password = '';
  loading = signal(false);
  error = signal('');

  submit() {
    this.loading.set(true);
    this.error.set('');
    this.auth.login(this.password).subscribe({
      next: () => this.router.navigate(['/admin']),
      error: (e) => {
        this.error.set(e.status === 429 ? 'Muitas tentativas. Aguarde 15 minutos.' : 'Senha incorreta.');
        this.loading.set(false);
      },
    });
  }
}
