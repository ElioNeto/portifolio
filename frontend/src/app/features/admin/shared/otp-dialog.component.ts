import { Component, input, output, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../../core/services/auth.service';

@Component({
  selector: 'app-otp-dialog',
  standalone: true,
  imports: [FormsModule, CommonModule],
  template: `
    <div class="overlay">
      <div class="dialog">
        <h3>Confirmação de segurança</h3>
        <p>Um código foi enviado para o email cadastrado. Insira abaixo para confirmar a ação.</p>
        <input
          type="text"
          [(ngModel)]="code"
          placeholder="000000"
          maxlength="6"
          autocomplete="one-time-code"
        />
        @if (error()) { <p class="error">{{ error() }}</p> }
        <div class="actions">
          <button class="btn-primary" (click)="confirm()">Confirmar</button>
          <button (click)="cancelled.emit()">Cancelar</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.8); display: flex; align-items: center; justify-content: center; z-index: 200; }
    .dialog { background: #111; border: 1px solid #333; border-radius: 12px; padding: 2rem; width: 380px; display: flex; flex-direction: column; gap: 1rem; }
    h3 { margin: 0; color: #fff; }
    p { color: #aaa; font-size: 0.875rem; margin: 0; }
    input { background: #1a1a1a; border: 1px solid #333; color: #fff; padding: 0.75rem; border-radius: 8px; font-size: 1.5rem; letter-spacing: 0.5rem; text-align: center; width: 100%; box-sizing: border-box; }
    .actions { display: flex; gap: 0.75rem; }
    .btn-primary { background: #6366f1; color: #fff; border: none; padding: 0.6rem 1.2rem; border-radius: 8px; cursor: pointer; }
    button:not(.btn-primary) { background: none; border: 1px solid #333; color: #aaa; padding: 0.6rem 1.2rem; border-radius: 8px; cursor: pointer; }
    .error { color: #f87171; font-size: 0.8rem; margin: 0; }
  `],
})
export class OtpDialogComponent {
  readonly purpose = input.required<string>();
  readonly confirmed = output<void>();
  readonly cancelled = output<void>();

  private readonly auth = inject(AuthService);
  code = '';
  error = signal('');

  confirm() {
    this.auth.validateOTP(this.purpose(), this.code).subscribe({
      next: () => this.confirmed.emit(),
      error: () => this.error.set('Código inválido ou expirado.'),
    });
  }
}
