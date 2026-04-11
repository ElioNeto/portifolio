import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ContactService } from '../../core/services/contact.service';

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss']
})
export class ContactComponent {
  private readonly contactService = inject(ContactService);

  sent = signal(false);
  loading = signal(false);
  form = { name: '', email: '', message: '' };

  onSubmit(): void {
    if (!this.form.name || !this.form.email || !this.form.message) {
      return;
    }

    this.loading.set(true);
    this.contactService.submitForm(this.form).subscribe({
      next: () => {
        this.loading.set(false);
        this.sent.set(true);
      },
      error: () => {
        this.loading.set(false);
      }
    });
  }
}
