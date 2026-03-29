import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AdminService } from '../../../core/services/admin.service';
import { AuthService } from '../../../core/services/auth.service';
import { PortfolioService } from '../../../core/services/portfolio.service';
import { Project } from '../../../core/models/portfolio.models';
import { OtpDialogComponent } from '../shared/otp-dialog.component';

@Component({
  selector: 'app-projects-admin',
  standalone: true,
  imports: [CommonModule, FormsModule, OtpDialogComponent],
  template: `
    <div class="section">
      <div class="header">
        <h2>Projetos</h2>
        <button class="btn-primary" (click)="openCreate()">+ Novo</button>
      </div>

      <table>
        <thead><tr><th>Título</th><th>Destaque</th><th>Ações</th></tr></thead>
        <tbody>
          @for (p of projects(); track p.id) {
            <tr>
              <td>{{ p.title }}</td>
              <td>{{ p.featured ? '⭐' : '—' }}</td>
              <td>
                <button class="btn-sm" (click)="openEdit(p)">Editar</button>
                <button class="btn-sm danger" (click)="requestDelete(p.id)">Excluir</button>
              </td>
            </tr>
          }
        </tbody>
      </table>

      @if (editing()) {
        <div class="modal-overlay" (click)="closeForm()">
          <div class="modal" (click)="$event.stopPropagation()">
            <h3>{{ form.id ? 'Editar' : 'Novo' }} Projeto</h3>
            <label>Título</label>
            <input [(ngModel)]="form.title" name="title" />
            <label>Descrição PT</label>
            <textarea [(ngModel)]="form.description['pt']" rows="3"></textarea>
            <label>Descrição EN</label>
            <textarea [(ngModel)]="form.description['en']" rows="3"></textarea>
            <label>Descrição ES</label>
            <textarea [(ngModel)]="form.description['es']" rows="3"></textarea>
            <label>Tecnologias (separadas por vírgula)</label>
            <input [(ngModel)]="techStr" name="tech" />
            <label>GitHub URL</label>
            <input [(ngModel)]="form.github" name="github" />
            <label>Live URL</label>
            <input [(ngModel)]="form.live" name="live" />
            <label class="checkbox">
              <input type="checkbox" [(ngModel)]="form.featured" name="featured" /> Destaque
            </label>
            <div class="actions">
              <button class="btn-primary" (click)="save()">Salvar</button>
              <button (click)="closeForm()">Cancelar</button>
            </div>
          </div>
        </div>
      }

      @if (otpPendingId()) {
        <app-otp-dialog
          purpose="delete-project"
          (confirmed)="confirmDelete()"
          (cancelled)="otpPendingId.set(null)"
        />
      }
    </div>
  `,
  styles: [`
    .section { max-width: 900px; }
    .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; }
    h2 { margin: 0; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 0.75rem; border-bottom: 1px solid #222; text-align: left; }
    th { color: #888; font-size: 0.8rem; text-transform: uppercase; }
    .btn-primary { background: #6366f1; color: #fff; border: none; padding: 0.5rem 1rem; border-radius: 8px; cursor: pointer; }
    .btn-sm { background: #1e1e2e; color: #aaa; border: 1px solid #333; padding: 0.3rem 0.6rem; border-radius: 6px; cursor: pointer; margin-right: 0.4rem; font-size: 0.8rem; }
    .btn-sm.danger:hover { border-color: #f87171; color: #f87171; }
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 100; }
    .modal { background: #111; border: 1px solid #333; border-radius: 12px; padding: 2rem; width: 560px; max-height: 90vh; overflow-y: auto; display: flex; flex-direction: column; gap: 0.5rem; }
    label { color: #aaa; font-size: 0.8rem; }
    input, textarea { background: #1a1a1a; border: 1px solid #333; color: #fff; padding: 0.6rem; border-radius: 8px; width: 100%; box-sizing: border-box; }
    .checkbox { display: flex; align-items: center; gap: 0.5rem; }
    .checkbox input { width: auto; }
    .actions { display: flex; gap: 0.75rem; margin-top: 0.5rem; }
  `],
})
export class ProjectsAdminComponent implements OnInit {
  private readonly admin = inject(AdminService);
  private readonly portfolio = inject(PortfolioService);
  private readonly auth = inject(AuthService);

  projects = signal<Project[]>([]);
  editing = signal(false);
  otpPendingId = signal<number | null>(null);
  techStr = '';

  form: Project = this.emptyForm();

  ngOnInit() {
    this.load();
  }

  load() {
    this.portfolio.getProjects().subscribe((p) => this.projects.set(p));
  }

  emptyForm(): Project {
    return { id: 0, title: '', description: { pt: '', en: '', es: '' }, tech: [], github: '', live: '', featured: false };
  }

  openCreate() {
    this.form = this.emptyForm();
    this.techStr = '';
    this.editing.set(true);
  }

  openEdit(p: Project) {
    this.form = { ...p, description: { ...p.description } };
    this.techStr = p.tech.join(', ');
    this.editing.set(true);
  }

  closeForm() { this.editing.set(false); }

  save() {
    this.form.tech = this.techStr.split(',').map((t) => t.trim()).filter(Boolean);
    const obs = this.form.id
      ? this.admin.updateProject(this.form)
      : this.admin.createProject(this.form);
    obs.subscribe(() => { this.closeForm(); this.load(); });
  }

  requestDelete(id: number) {
    this.otpPendingId.set(id);
    this.auth.sendOTP('delete-project').subscribe();
  }

  confirmDelete() {
    const id = this.otpPendingId();
    if (!id) return;
    this.admin.deleteProject(id).subscribe(() => {
      this.otpPendingId.set(null);
      this.load();
    });
  }
}
