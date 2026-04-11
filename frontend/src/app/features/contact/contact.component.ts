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
  templateUrl: './contact.component.html',
  styleUrls: ['./contact.component.scss']
})
export class ContactComponent {
  sent = signal(false);
  form: ContactForm = { name: '', email: '', message: '' };

  onSubmit(): void {
    console.log('Form submitted', this.form);
    this.sent.set(true);
  }
}
