import { Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

interface ContactForm {
  name: string;
  email: string;
  message: string;
}

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [FormsModule],
  template: `
    <section id="contact" class="container">
      <h2 i18n="@@contact.title">Get in Touch</h2>
      @if (!sent()) {
        <form (ngSubmit)="onSubmit()" #f="ngForm" class="contact-form">
          <div class="form-group">
            <label for="name" i18n="@@contact.name">Name</label>
            <input
              id="name" name="name" type="text"
              [(ngModel)]="form.name" required
              [placeholder]="namePlaceholder"
            />
          </div>
          <div class="form-group">
            <label for="email" i18n="@@contact.email">Email</label>
            <input
              id="email" name="email" type="email"
              [(ngModel)]="form.email" required
              [placeholder]="emailPlaceholder"
            />
          </div>
          <div class="form-group">
            <label for="message" i18n="@@contact.message">Message</label>
            <textarea
              id="message" name="message"
              [(ngModel)]="form.message" required rows="5"
              [placeholder]="messagePlaceholder"
            ></textarea>
          </div>
          <button type="submit" [disabled]="f.invalid" i18n="@@contact.send">Send Message</button>
        </form>
      } @else {
        <div class="success-msg">
          <p i18n="@@contact.success">Thanks! I'll get back to you soon. 🚀</p>
        </div>
      }
    </section>
  `,
  styles: [`
    .contact-form { max-width: 600px; display: flex; flex-direction: column; gap: 1.25rem; }
    .form-group { display: flex; flex-direction: column; gap: 0.5rem; }
    label { font-size: 0.875rem; font-weight: 600; color: var(--color-text-muted); }
    input, textarea {
      padding: 0.875rem;
      background: var(--color-surface);
      border: 1px solid var(--color-border);
      border-radius: var(--radius);
      color: var(--color-text);
      font-family: var(--font-family);
      font-size: 0.95rem;
      transition: border-color var(--transition);
    }
    input:focus, textarea:focus { outline: none; border-color: var(--color-primary); }
    button {
      padding: 0.875rem 2rem;
      background: var(--color-primary);
      color: #0a0e1a;
      border: none;
      border-radius: var(--radius);
      font-weight: 700;
      font-size: 1rem;
      cursor: pointer;
      transition: opacity var(--transition);
      align-self: flex-start;
    }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    button:hover:not(:disabled) { opacity: 0.85; }
    .success-msg { padding: 2rem; background: var(--color-surface); border-radius: var(--radius); border-left: 4px solid var(--color-primary); }
    .success-msg p { font-size: 1.1rem; }
  `]
})
export class ContactComponent {
  sent = signal(false);
  form: ContactForm = { name: '', email: '', message: '' };

  namePlaceholder = $localize`:@@contact.name.placeholder:Your name`;
  emailPlaceholder = $localize`:@@contact.email.placeholder:your@email.com`;
  messagePlaceholder = $localize`:@@contact.message.placeholder:Tell me about your project...`;

  onSubmit(): void {
    // TODO: connect to backend /api/contact
    console.log('Form submitted', this.form);
    this.sent.set(true);
  }
}
