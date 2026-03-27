import { Component } from '@angular/core';

@Component({
  selector: 'app-footer',
  standalone: true,
  template: `
    <footer>
      <div class="container">
        <p>
          &copy; {{ year }} Elio Neto &mdash;
          <a href="https://github.com/ElioNeto" target="_blank" rel="noopener">
            ${ $localize`:@@footer.builtWith:Built with Angular + Go` }
          </a>
        </p>
      </div>
    </footer>
  `,
  styles: [`
    footer {
      border-top: 1px solid var(--color-border);
      padding: 2rem 0;
      text-align: center;
      color: var(--color-text-muted);
      font-size: 0.875rem;
    }
  `]
})
export class FooterComponent {
  year = new Date().getFullYear();
}
