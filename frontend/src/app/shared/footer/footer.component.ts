import { Component } from '@angular/core';

@Component({
  selector: 'app-footer',
  standalone: true,
  template: `
    <footer>
      <div class="container">
        <p>
          &copy; {{ year }}
          <a href="https://github.com/ElioNeto" target="_blank" rel="noopener">
            <ng-container i18n="@@footer.builtWith">Elio Neto &mdash; Built with Angular + Go</ng-container>
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
    a { color: var(--color-text-muted); }
    a:hover { color: var(--color-primary); }
  `]
})
export class FooterComponent {
  year = new Date().getFullYear();
}
