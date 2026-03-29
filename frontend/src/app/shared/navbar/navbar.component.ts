import { Component, HostListener, signal } from '@angular/core';

interface NavLink {
  anchor: string;
  label: string;
}

@Component({
  selector: 'app-navbar',
  standalone: true,
  template: `
    <nav [class.scrolled]="scrolled()">
      <div class="container nav-inner">
        <span class="logo">EN</span>
        <ul class="nav-links">
          @for (link of navLinks; track link.anchor) {
            <li><a [href]="link.anchor">{{ link.label }}</a></li>
          }
        </ul>
      </div>
    </nav>
  `,
  styles: [`
    nav {
      position: fixed; top: 0; width: 100%; z-index: 100;
      padding: 1.25rem 0;
      transition: all 0.3s ease;
    }
    nav.scrolled {
      background: rgba(10,14,26,0.95);
      backdrop-filter: blur(10px);
      padding: 0.75rem 0;
      border-bottom: 1px solid var(--color-border);
    }
    .nav-inner { display: flex; align-items: center; justify-content: space-between; }
    .logo { font-size: 1.5rem; font-weight: 800; color: var(--color-primary); }
    .nav-links { display: flex; gap: 2rem; list-style: none; }
    .nav-links a { color: var(--color-text-muted); font-size: 0.9rem; font-weight: 500; transition: color 0.2s; }
    .nav-links a:hover { color: var(--color-text); }
  `]
})
export class NavbarComponent {
  scrolled = signal(false);

  navLinks: NavLink[] = [
    { anchor: '#about',    label: 'Sobre' },
    { anchor: '#projects', label: 'Projetos' },
    { anchor: '#skills',   label: 'Skills' },
    { anchor: '#contact',  label: 'Contato' },
  ];

  @HostListener('window:scroll')
  onScroll(): void {
    this.scrolled.set(window.scrollY > 50);
  }
}
