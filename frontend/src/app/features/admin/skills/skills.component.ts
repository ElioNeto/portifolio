import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AdminService } from '../../../core/services/admin.service';
import { AuthService } from '../../../core/services/auth.service';
import { PortfolioService } from '../../../core/services/portfolio.service';
import { Skill } from '../../../core/models/portfolio.models';
import { OtpDialogComponent } from '../shared/otp-dialog.component';

@Component({
  selector: 'app-skills-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, OtpDialogComponent],
  template: `
    <div class="section">
      <div class="header">
        <h2>Skills</h2>
        <button class="btn-primary" (click)="openCreate()">+ Nova</button>
      </div>

      <table>
        <thead><tr><th>Nome</th><th>Categoria</th><th>Nível</th><th>Ações</th></tr></thead>
        <tbody>
          @for (s of skills(); track s.id) {
            <tr>
              <td>{{ s.name }}</td>
              <td>{{ s.category }}</td>
              <td>{{ s.level }}</td>
              <td>
                <button class="btn-sm" (click)="openEdit(s)">Editar</button>
                <button class="btn-sm danger" (click)="requestDelete(s.id)">Excluir</button>
              </td>
            </tr>
          }
        </tbody>
      </table>

      @if (editing()) {
        <div class="modal-overlay" (click)="closeForm()">
          <div class="modal" (click)="$event.stopPropagation()">
            <h3>{{ form.id ? 'Editar' : 'Nova' }} Skill</h3>
            <label>Nome</label>
            <input [(ngModel)]="form.name" name="name" />
            <label>Categoria</label>
            <input [(ngModel)]="form.category" name="category" />
            <label>Nível (0–100)</label>
            <input type="number" [(ngModel)]="form.level" name="level" min="0" max="100" />
            <div class="actions">
              <button class="btn-primary" (click)="save()">Salvar</button>
              <button (click)="closeForm()">Cancelar</button>
            </div>
          </div>
        </div>
      }

      @if (otpPendingId()) {
        <app-otp-dialog
          purpose="delete-skill"
          (confirmed)="confirmDelete()"
          (cancelled)="otpPendingId.set(null)"
        />
      }
    </div>
  `,
  styles: [`
    .section { max-width: 700px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    h2 { margin: 0; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 0.75rem; border-bottom: 1px solid #222; text-align: left; }
    th { color: #888; font-size: 0.8rem; text-transform: uppercase; }
    .btn-primary { background: #6366f1; color: #fff; border: none; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; }
    .btn-sm { background: #1e1e2e; color: #aaa; border: 1px solid #333; padding: 0.3rem 0.6rem; border-radius: 6px; cursor: pointer; margin-right: 0.4rem; font-size: 0.8rem; }
    .btn-sm.danger:hover { border-color: #f87171; color: #f87171; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 100; }
    .modal { background: #111; border: 1px solid #333; border-radius: 12px; padding: 2rem; width: 400px; display: flex; flex-direction: column; gap: 0.5rem; }
    label { color: #aaa; font-size: 0.8rem; }
    input { background: #1a1a1a; border: 1px solid #333; color: #fff; padding: 0.6rem; border-radius: 8px; width: 100%; box-sizing: border-box; }
    .actions { display: flex; gap: 0.75rem; margin-top: 0.5rem; }
  `],
})
export class SkillsAdminComponent implements OnInit {
  private readonly admin = inject(AdminService);
  private readonly portfolio = inject(PortfolioService);
  private readonly auth = inject(AuthService);

  skills = signal<Skill[]>([]);
  editing = signal(false);
  otpPendingId = signal<number | null>(null);
  form: Skill = this.emptyForm();

  ngOnInit() { this.load(); }

  load() {
    this.portfolio.getSkills().subscribe((s) => this.skills.set(s));
  }

  emptyForm(): Skill {
    return { id: 0, name: '', category: '', level: 80 };
  }

  openCreate() { this.form = this.emptyForm(); this.editing.set(true); }
  openEdit(s: Skill) { this.form = { ...s }; this.editing.set(true); }
  closeForm() { this.editing.set(false); }

  save() {
    const obs = this.form.id
      ? this.admin.updateSkill(this.form)
      : this.admin.createSkill(this.form);
    obs.subscribe(() => { this.closeForm(); this.load(); });
  }

  requestDelete(id: number) {
    this.otpPendingId.set(id);
    this.auth.sendOTP('delete-skill').subscribe();
  }

  confirmDelete() {
    const id = this.otpPendingId();
    if (!id) return;
    this.admin.deleteSkill(id).subscribe(() => {
      this.otpPendingId.set(null);
      this.load();
    });
  }
}
